-- Shared GitHub workflow utilities.
--
-- Pure logic used by both:
--   * plugin/gh.lua  - interactive use inside your main Neovim
--   * cli/gh.lua     - standalone TUI launched from a terminal shell
--
-- Everything here drives `gh`/`git` via `vim.system` and renders with Snacks,
-- so there is a single source of truth shared by Neovim and the terminal.

local M = {}

M.VALID_TABS = {
  'actions',
  'pulls',
  'issues',
  'wiki',
  'security',
  'releases',
  'projects',
  'discussions',
  'packages',
}

-- Run a command synchronously, returning trimmed stdout on success or
-- nil + stderr on failure. Reserve this for *local* git reads (rev-parse,
-- remote get-url, branch -r) that return in well under a millisecond — never
-- for `gh` (Node cold-start) or anything that touches the network.
---@param cmd string[]
---@return string? out, string? err
local function run(cmd)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 then
    return nil, (res.stderr ~= '' and res.stderr or res.stdout) or ('exit ' .. res.code)
  end
  return (res.stdout or ''):gsub('%s+$', ''), nil
end

-- Run a command without blocking the UI. `cb(out, err)` fires on the main loop.
---@param cmd string[]
---@param cb fun(out: string?, err: string?)
local function run_async(cmd, cb)
  vim.system(cmd, { text = true }, function(res)
    local out, err
    if res.code ~= 0 then
      err = (res.stderr ~= '' and res.stderr or res.stdout) or ('exit ' .. res.code)
    else
      out = (res.stdout or ''):gsub('%s+$', '')
    end
    vim.schedule(function()
      cb(out, err)
    end)
  end)
end

-- Cached `gh auth status` result for the session (nil = not yet checked).
-- The check is a network round-trip, so we pay it once and reuse it.
local auth_ok = nil

-- Shared preflight: ensure gh exists, we're in a repo, and gh is authed.
-- Async so the (networked) auth check never freezes the editor; `cb(ok)` fires
-- on the main loop.
---@param need_gh boolean whether the `gh` CLI + auth are required
---@param cb fun(ok: boolean)
local function preflight_async(need_gh, cb)
  if need_gh ~= false and vim.fn.executable 'gh' == 0 then
    vim.notify('gh CLI is not installed. See https://cli.github.com/', vim.log.levels.ERROR)
    return cb(false)
  end
  -- Local, instant — safe to check synchronously.
  if vim.fn.executable 'git' == 1 then
    local _, err = run { 'git', 'rev-parse', '--git-dir' }
    if err then
      vim.notify('Not in a Git repository.', vim.log.levels.ERROR)
      return cb(false)
    end
  end
  if need_gh == false or auth_ok == true then
    return cb(true)
  end
  run_async({ 'gh', 'auth', 'status' }, function(_, err)
    if err then
      auth_ok = false
      vim.notify("gh CLI is not authenticated. Run 'gh auth login' first.", vim.log.levels.ERROR)
      return cb(false)
    end
    auth_ok = true
    cb(true)
  end)
end

-- Invoke an optional completion callback (used by the headless CLI to quit).
local function done(cb)
  if type(cb) == 'function' then
    cb()
  end
end

----------------------------------------------------------------------
-- Shared rendering helpers (status icons, time formatting, alignment)
----------------------------------------------------------------------

local STATUS_ICON = {
  success = '✓',
  completed = '✓',
  failure = '✗',
  cancelled = '⊘',
  skipped = '⊙',
  in_progress = '●',
  queued = '○',
  pending = '○',
  waiting = '○',
  neutral = '◆',
}

local STATUS_HL = {
  success = 'DiagnosticOk',
  completed = 'DiagnosticOk',
  failure = 'DiagnosticError',
  cancelled = 'DiagnosticWarn',
  skipped = 'Comment',
  in_progress = 'DiagnosticInfo',
  queued = 'DiagnosticHint',
  pending = 'DiagnosticHint',
  neutral = 'Normal',
}

local SPINNER = { '◐', '◓', '◑', '◒' }

-- Resolve a job/step/run into an icon key based on status + conclusion.
local function status_key(status, conclusion)
  if status == 'completed' then
    return conclusion or 'completed'
  end
  return status or 'pending'
end

-- Parse a GitHub ISO-8601 UTC timestamp ("2024-01-02T03:04:05Z") to a local
-- epoch. Returns nil on anything unparseable (e.g. an empty startedAt).
---@param ts string?
---@return integer? epoch
local function parse_iso(ts)
  if not ts then
    return nil
  end
  local y, mo, d, h, mi, s = ts:match '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z'
  if not y then
    return nil
  end
  -- os.time treats the fields as *local* wall-clock, so it returns an epoch
  -- that is off by the local↔UTC offset. Add the offset back to recover the
  -- true epoch. (`os.date '!*t'` is UTC; os.time of it reads as local, so the
  -- difference from os.time() is exactly that offset.)
  local utc_offset = os.time() - os.time(os.date '!*t')
  return os.time {
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
    isdst = false,
  } + utc_offset
end

-- Human "3m ago" / "2h ago" / "Jul 1" style relative time from an epoch.
---@param epoch integer?
---@return string
local function rel_time(epoch)
  if not epoch then
    return ''
  end
  local diff = os.time() - epoch
  if diff < 0 then
    diff = 0
  end
  if diff < 60 then
    return diff .. 's ago'
  elseif diff < 3600 then
    return math.floor(diff / 60) .. 'm ago'
  elseif diff < 86400 then
    return math.floor(diff / 3600) .. 'h ago'
  elseif diff < 7 * 86400 then
    return math.floor(diff / 86400) .. 'd ago'
  end
  return os.date('%b %d', epoch) --[[@as string]]
end

-- Compact duration ("1m 36s" / "45s") from a number of seconds.
---@param secs number?
---@return string
local function fmt_dur(secs)
  if not secs or secs < 0 then
    return ''
  end
  secs = math.floor(secs)
  if secs >= 60 then
    return ('%dm %ds'):format(math.floor(secs / 60), secs % 60)
  end
  return secs .. 's'
end

-- Right-pad `str` to `width` display columns (unicode-aware).
---@param str string
---@param width integer
---@return string
local function pad(str, width)
  local n = width - vim.fn.strdisplaywidth(str)
  return n > 0 and (str .. string.rep(' ', n)) or str
end

-- Truncate `str` to at most `width` display columns, adding "…" if cut.
---@param str string
---@param width integer
---@return string
local function truncate(str, width)
  if vim.fn.strdisplaywidth(str) <= width then
    return str
  end
  return vim.fn.strcharpart(str, 0, math.max(width - 1, 1)) .. '…'
end

-- Assemble a line from { text, hl? } segments into a string plus byte-accurate
-- highlight specs ({ col, end_col, hl }) for extmarks.
---@param segments table[]  -- each: { string, string? }
---@return string text, table[] hls
local function seg_line(segments)
  local text, hls, col = '', {}, 0
  for _, s in ipairs(segments) do
    local t = s[1] or ''
    if s[2] and t ~= '' then
      hls[#hls + 1] = { col = col, end_col = col + #t, hl = s[2] }
    end
    text = text .. t
    col = col + #t
  end
  return text, hls
end

----------------------------------------------------------------------
-- ghb: open a repo tab in the browser
----------------------------------------------------------------------

---@return string? url
local function repo_url()
  local remote, err = run { 'git', 'remote', 'get-url', 'origin' }
  if err or not remote then
    vim.notify('Could not fetch origin remote.', vim.log.levels.ERROR)
    return nil
  end
  local url
  if remote:match '^git@github%.com:' then
    url = remote:gsub('^git@github%.com:', 'https://github.com/')
  elseif remote:match '^https://github%.com/' then
    url = remote
  else
    vim.notify('Origin remote is not a GitHub repo: ' .. remote, vim.log.levels.ERROR)
    return nil
  end
  return (url:gsub('%.git$', ''))
end

---@param tab? string
---@param on_done? fun()
function M.ghb(tab, on_done)
  preflight_async(false, function(ok)
    if not ok then
      return done(on_done)
    end

    local function open(t)
      if not vim.tbl_contains(M.VALID_TABS, t) then
        vim.notify('Invalid tab: ' .. t .. '. Valid: ' .. table.concat(M.VALID_TABS, ', '), vim.log.levels.ERROR)
        return
      end
      local base = repo_url()
      if base then
        vim.ui.open(base .. '/' .. t)
      end
    end

    if tab and tab ~= '' then
      open(tab)
      return done(on_done)
    end

    Snacks.picker.select(M.VALID_TABS, { prompt = 'GitHub tab' }, function(choice)
      if choice then
        open(choice)
      end
      done(on_done)
    end)
  end)
end

----------------------------------------------------------------------
-- Workflow selection (shared by ghwl, ghwr, ghws)
----------------------------------------------------------------------

-- Pick a workflow by name via the picker. `on_cancel` fires when nothing is
-- chosen so callers (e.g. the headless CLI) can quit.
---@param prompt string
---@param cb fun(name: string)
---@param on_cancel? fun()
local function pick_workflow(prompt, cb, on_cancel)
  run_async({ 'gh', 'workflow', 'list', '--all' }, function(out, err)
    if err then
      vim.notify('Failed to fetch workflows.\n' .. (err or ''), vim.log.levels.ERROR)
      return done(on_cancel)
    end
    local items = {}
    for line in (out or ''):gmatch '[^\n]+' do
      -- gh workflow list is tab-delimited: NAME\tSTATE\tID
      local name = line:match '^(.-)\t' or line
      if name and name ~= '' then
        items[#items + 1] = { name = name, text = line }
      end
    end
    if #items == 0 then
      vim.notify('No workflows found.', vim.log.levels.WARN)
      return done(on_cancel)
    end
    Snacks.picker.select(items, {
      prompt = prompt,
      format_item = function(it)
        return it.text
      end,
    }, function(choice)
      if choice then
        cb(choice.name)
      else
        done(on_cancel)
      end
    end)
  end)
end

----------------------------------------------------------------------
-- ghwl: list runs for a selected workflow
----------------------------------------------------------------------

-- Show recent runs for a named workflow as an aligned, colorized table.
---@param name string
---@param limit integer
---@param on_done? fun()
local function list_runs(name, limit, on_done)
  run_async({
    'gh',
    'run',
    'list',
    '--workflow=' .. name,
    '--limit=' .. tostring(limit),
    '--json',
    'conclusion,createdAt,displayTitle,event,headBranch,number,startedAt,status,updatedAt',
  }, function(out, err)
    if err then
      vim.notify('Failed to fetch workflow runs.\n' .. (err or ''), vim.log.levels.ERROR)
      return done(on_done)
    end
    local ok, runs = pcall(vim.json.decode, out or '[]')
    if not ok or type(runs) ~= 'table' then
      vim.notify('Failed to parse workflow runs.', vim.log.levels.ERROR)
      return done(on_done)
    end
    if #runs == 0 then
      vim.notify("No runs found for '" .. name .. "'", vim.log.levels.WARN)
      return done(on_done)
    end

    -- Size the number/branch columns to the data (branch capped so a long
    -- branch name can't blow out the layout).
    local num_w, br_w = 0, 8
    for _, r in ipairs(runs) do
      num_w = math.max(num_w, #('#' .. tostring(r.number or 0)))
      br_w = math.max(br_w, vim.fn.strdisplaywidth(r.headBranch or ''))
    end
    br_w = math.min(br_w, 30)

    local lines, hls = {}, {}
    local function add(text, specs)
      lines[#lines + 1] = text
      if specs then
        local lnum = #lines - 1
        for _, h in ipairs(specs) do
          hls[#hls + 1] = { line = lnum, col = h.col, end_col = h.end_col, hl = h.hl }
        end
      end
    end

    local header = (' %d run%s'):format(#runs, #runs == 1 and '' or 's')
    add(header, { { col = 0, end_col = #header, hl = 'Title' } })
    add('', nil)

    for _, r in ipairs(runs) do
      local key = status_key(r.status, r.conclusion)
      local icon = STATUS_ICON[key] or '◆'
      local ihl = STATUS_HL[key] or 'Normal'

      -- Duration: elapsed for completed runs, running time otherwise.
      local dur = ''
      local started = parse_iso(r.startedAt)
      if r.status == 'completed' then
        local finished = parse_iso(r.updatedAt)
        if started and finished then
          dur = fmt_dur(finished - started)
        end
      elseif started then
        dur = fmt_dur(os.time() - started)
      end

      local text, seg_hls = seg_line {
        { ' ' },
        { icon, ihl },
        { '  ' },
        { pad('#' .. tostring(r.number or 0), num_w), 'Comment' },
        { '  ' },
        { pad(truncate(r.headBranch or '', br_w), br_w), 'Function' },
        { '  ' },
        { pad(r.event or '', 18), 'Comment' },
        { '  ' },
        { pad(rel_time(parse_iso(r.createdAt)), 9), 'Comment' },
        { '  ' },
        { dur, 'Constant' },
      }
      add(text, seg_hls)
    end

    local win = Snacks.win {
      title = ' ' .. name .. ' ',
      text = lines,
      width = 0.8,
      height = 0.6,
      border = 'rounded',
      wo = { wrap = false, cursorline = true },
      bo = { filetype = 'ghruns', modifiable = false },
      keys = { q = 'close', ['<esc>'] = 'close' },
    }

    -- Paint highlights once the buffer exists.
    local ns = vim.api.nvim_create_namespace 'ghruns'
    if win.buf and vim.api.nvim_buf_is_valid(win.buf) then
      for _, h in ipairs(hls) do
        pcall(vim.api.nvim_buf_set_extmark, win.buf, ns, h.line, h.col, {
          end_col = h.end_col,
          hl_group = h.hl,
        })
      end
    end

    if on_done then
      win:on('WinClosed', on_done, { win = true })
    end
  end)
end

---@param limit? integer
---@param on_done? fun()
function M.ghwl(limit, on_done)
  preflight_async(true, function(ok)
    if not ok then
      return done(on_done)
    end
    pick_workflow('Workflow runs', function(name)
      list_runs(name, limit or 20, on_done)
    end, on_done)
  end)
end

----------------------------------------------------------------------
-- ghwr: pick a workflow + branch, then trigger a run
----------------------------------------------------------------------

-- Pick a remote branch for a named workflow and trigger a run on it.
---@param name string
---@param on_done? fun()
local function run_on_branch(name, on_done)
  -- Refresh remote refs in the background so the *next* run is current,
  -- but don't block the picker on a network fetch — show local refs now.
  run_async({ 'git', 'fetch', '--quiet' }, function() end)

  local out, err = run { 'git', 'branch', '-r' } -- local, instant
  if err then
    vim.notify('Failed to list remote branches.', vim.log.levels.ERROR)
    return done(on_done)
  end
  local branches = {}
  for line in (out or ''):gmatch '[^\n]+' do
    if not line:match 'HEAD' then
      local b = line:gsub('%s+', ''):gsub('^origin/', '')
      if b ~= '' then
        branches[#branches + 1] = b
      end
    end
  end
  if #branches == 0 then
    vim.notify('No remote branches found.', vim.log.levels.ERROR)
    return done(on_done)
  end
  Snacks.picker.select(branches, { prompt = 'Branch for ' .. name }, function(branch)
    if not branch then
      return done(on_done)
    end
    run_async({ 'gh', 'workflow', 'run', name, '--ref', branch }, function(_, run_err)
      if run_err then
        vim.notify('Failed to trigger workflow.\n' .. (run_err or ''), vim.log.levels.ERROR)
        return done(on_done)
      end
      vim.notify(('Triggered "%s" on %s'):format(name, branch), vim.log.levels.INFO, { title = 'GitHub Workflow' })
      done(on_done)
    end)
  end)
end

---@param on_done? fun()
function M.ghwr(on_done)
  preflight_async(true, function(ok)
    if not ok then
      return done(on_done)
    end
    pick_workflow('Run workflow', function(name)
      run_on_branch(name, on_done)
    end, on_done)
  end)
end

----------------------------------------------------------------------
-- ghws: live monitor the latest run of a selected workflow (native panel)
----------------------------------------------------------------------

-- Build the rendered lines + highlight specs for a run payload.
---@param data table decoded `gh run view --json ...`
---@param frame integer spinner frame index
---@return string[] lines, table[] hls  -- hls: { line=0-based, col, end_col, hl }
local function render(data, frame)
  local lines, hls = {}, {}
  local spinner = SPINNER[(frame % #SPINNER) + 1]

  local function add(text, hl_specs)
    lines[#lines + 1] = text
    if hl_specs then
      local lnum = #lines - 1
      for _, h in ipairs(hl_specs) do
        hls[#hls + 1] = { line = lnum, col = h[1], end_col = h[2], hl = h[3] }
      end
    end
  end

  local status = data.status or 'unknown'
  local conclusion = data.conclusion
  local title = data.displayTitle or 'N/A'

  -- Run header line with status icon.
  local rkey = status_key(status, conclusion)
  local ricon = (status == 'in_progress') and spinner or (STATUS_ICON[rkey] or '◆')
  local rhl = (status == 'in_progress') and 'DiagnosticInfo' or (STATUS_HL[rkey] or 'Normal')
  local header = (' %s %s'):format(ricon, title)
  add(header, { { 1, 1 + #ricon, rhl } })

  -- Meta lines.
  add('   ' .. ('branch  %s'):format(data.headBranch or 'N/A'), { { 3, 9, 'Comment' } })

  -- Elapsed time.
  local created_epoch = parse_iso(data.createdAt)
  if created_epoch then
    local elapsed = os.time() - created_epoch
    if elapsed >= 0 then
      add('   ' .. ('elapsed %s'):format(fmt_dur(elapsed)), { { 3, 10, 'Comment' } })
    end
  end

  add('', nil)

  local jobs = data.jobs or {}

  -- Progress bar based on steps across all jobs.
  local total, completed = 0, 0
  for _, job in ipairs(jobs) do
    for _, step in ipairs(job.steps or {}) do
      total = total + 1
      if step.status == 'completed' or step.conclusion == 'skipped' then
        completed = completed + 1
      end
    end
  end
  if total > 0 and status ~= 'completed' then
    local pct = math.floor(completed * 100 / total)
    local width = 40
    local filled = math.floor(completed * width / total)
    local bar = string.rep('▓', filled) .. string.rep('░', width - filled)
    local line = (' %s %3d%% (%d/%d steps)'):format(bar, pct, completed, total)
    add(line, { { 1, 1 + #('▓'):rep(filled), 'DiagnosticInfo' } })
    add('', nil)
  end

  -- Jobs and their steps.
  for _, job in ipairs(jobs) do
    local jkey = status_key(job.status, job.conclusion)
    local jicon = (job.status == 'in_progress') and spinner or (STATUS_ICON[jkey] or '◆')
    local jhl = (job.status == 'in_progress') and 'DiagnosticInfo' or (STATUS_HL[jkey] or 'Normal')
    add((' %s %s'):format(jicon, job.name or 'job'), { { 1, 1 + #jicon, jhl } })

    for _, step in ipairs(job.steps or {}) do
      local skey = status_key(step.status, step.conclusion)
      local sicon = (step.status == 'in_progress') and spinner or (STATUS_ICON[skey] or '○')
      local shl = (step.status == 'in_progress') and 'DiagnosticInfo' or (STATUS_HL[skey] or 'Comment')
      add(('   %s %s'):format(sicon, step.name or 'step'), { { 3, 3 + #sicon, shl } })
    end
  end

  if status == 'completed' then
    add('', nil)
    local concl_hl = STATUS_HL[conclusion or 'neutral'] or 'Normal'
    add((' %s %s'):format(STATUS_ICON[conclusion or 'neutral'] or '◆', (conclusion or 'done'):upper()), { { 1, 3, concl_hl } })
    add('   q: close   o: open run in browser', { { 0, -1, 'Comment' } })
  else
    add('', nil)
    add('   q: close   monitoring…', { { 0, -1, 'Comment' } })
  end

  return lines, hls
end

-- Open the live monitor panel for a resolved run id and poll it until it
-- completes. All `gh run view` fetches are async; the spinner redraws from the
-- last payload between fetches so it animates without hammering `gh`.
---@param name string workflow name (window title)
---@param run_id integer|string
---@param on_done? fun()
local function monitor_run(name, run_id, on_done)
  local ns = vim.api.nvim_create_namespace 'ghws'
  local frame = 0
  local timer = assert(vim.uv.new_timer())
  local closed = false
  local run_url = nil

  local win = Snacks.win {
    title = ' ' .. name .. ' ',
    text = { ' Loading run ' .. run_id .. '…' },
    width = 0.7,
    height = 0.7,
    border = 'rounded',
    wo = { wrap = false, cursorline = false },
    bo = { filetype = 'ghws', modifiable = false },
    keys = {
      q = 'close',
      ['<esc>'] = 'close',
      o = function(self)
        if run_url then
          vim.ui.open(run_url)
        end
        self:close()
      end,
    },
  }

  local function stop()
    if closed then
      return
    end
    closed = true
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end

  -- Stop polling (and notify the caller) when the window closes.
  win:on('WinClosed', function()
    stop()
    done(on_done)
  end, { win = true })

  local last_data = nil
  local fetching = false

  -- Paint the buffer from a decoded payload (must run on the main loop).
  local function paint(data)
    if closed or not (win.buf and vim.api.nvim_buf_is_valid(win.buf)) then
      return
    end
    local lines, hls = render(data, frame)
    vim.bo[win.buf].modifiable = true
    vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, lines)
    vim.bo[win.buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(win.buf, ns, 0, -1)
    for _, h in ipairs(hls) do
      pcall(vim.api.nvim_buf_set_extmark, win.buf, ns, h.line, math.max(h.col, 0), {
        end_col = h.end_col == -1 and #(lines[h.line + 1] or '') or h.end_col,
        hl_group = h.hl,
      })
    end
  end

  -- Kick off an async `gh run view`; updates last_data and stops on completion.
  local function fetch()
    if fetching or closed then
      return
    end
    fetching = true
    vim.system({
      'gh',
      'run',
      'view',
      tostring(run_id),
      '--json',
      'status,conclusion,jobs,createdAt,updatedAt,displayTitle,headBranch,url',
    }, { text = true }, function(res)
      fetching = false
      if res.code ~= 0 then
        return
      end
      local okd, data = pcall(vim.json.decode, res.stdout or '{}')
      if not okd or type(data) ~= 'table' then
        return
      end
      last_data = data
      run_url = data.url or run_url
      vim.schedule(function()
        paint(data)
      end)
      if data.status == 'completed' then
        stop()
        if vim.fn.has 'mac' == 1 then
          local sound = data.conclusion == 'success' and 'Glass' or (data.conclusion == 'failure' and 'Basso' or nil)
          if sound then
            vim.system { 'afplay', '/System/Library/Sounds/' .. sound .. '.aiff' }
          end
        end
      end
    end)
  end

  -- Tick at 250ms for a smooth spinner; fetch fresh data every ~1.5s (6 ticks).
  timer:start(0, 250, function()
    if closed then
      return
    end
    frame = frame + 1
    vim.schedule(function()
      if closed or not (win.buf and vim.api.nvim_buf_is_valid(win.buf)) then
        stop()
        return
      end
      if last_data then
        paint(last_data)
      end
    end)
    if frame == 1 or frame % 6 == 0 then
      fetch()
    end
  end)
end

-- Resolve the latest run of a named workflow and open the live monitor.
---@param name string
---@param on_done? fun()
local function monitor_workflow(name, on_done)
  run_async({ 'gh', 'run', 'list', '--workflow=' .. name, '--limit=1', '--json', 'databaseId' }, function(out, err)
    if err then
      vim.notify('Failed to fetch workflow runs.\n' .. (err or ''), vim.log.levels.ERROR)
      return done(on_done)
    end
    local ok, parsed = pcall(vim.json.decode, out or '[]')
    local run_id = ok and parsed[1] and parsed[1].databaseId or nil
    if not run_id then
      vim.notify("No runs found for workflow '" .. name .. "'", vim.log.levels.WARN)
      return done(on_done)
    end
    monitor_run(name, run_id, on_done)
  end)
end

---@param on_done? fun()
function M.ghws(on_done)
  preflight_async(true, function(authed)
    if not authed then
      return done(on_done)
    end
    pick_workflow('Monitor workflow', function(name)
      monitor_workflow(name, on_done)
    end, on_done)
  end)
end

----------------------------------------------------------------------
-- ghw: one workflow picker; act on the selection via keymaps
--   <cr>  run on a branch     <c-s> monitor latest run
--   <c-l> list recent runs    <c-o> open workflow on github.com
----------------------------------------------------------------------

---@param on_done? fun()
function M.ghw(on_done)
  preflight_async(true, function(authed)
    if not authed then
      return done(on_done)
    end
    run_async({ 'gh', 'workflow', 'list', '--all' }, function(out, err)
      if err then
        vim.notify('Failed to fetch workflows.\n' .. (err or ''), vim.log.levels.ERROR)
        return done(on_done)
      end
      local items = {}
      for line in (out or ''):gmatch '[^\n]+' do
        -- gh workflow list is tab-delimited: NAME\tSTATE\tID
        local name, state, id = line:match '^(.-)\t(.-)\t(.*)$'
        name = name or line
        if name and name ~= '' then
          items[#items + 1] = { text = name, name = name, state = state or '', id = id or '' }
        end
      end
      if #items == 0 then
        vim.notify('No workflows found.', vim.log.levels.WARN)
        return done(on_done)
      end

      -- Wrap a name-taking action: grab the focused item, close the picker,
      -- then run. on_done is intentionally not threaded through the picker —
      -- these are interactive-only entry points.
      local function act(fn)
        return function(picker, item)
          item = item or picker:current()
          picker:close()
          if item and item.name then
            fn(item.name)
          end
        end
      end

      Snacks.picker.pick {
        items = items,
        title = 'GitHub Workflows',
        on_close = function()
          done(on_done)
        end,
        format = function(item)
          local active = item.state == 'active'
          return {
            { active and '● ' or '○ ', active and 'DiagnosticOk' or 'Comment' },
            { item.name, 'Normal' },
          }
        end,
        confirm = act(function(name)
          run_on_branch(name)
        end),
        actions = {
          gh_monitor = act(function(name)
            monitor_workflow(name)
          end),
          gh_runs = act(function(name)
            list_runs(name, 20)
          end),
          gh_browse = act(function(name)
            -- gh resolves the display name to the correct workflow file URL.
            run_async({ 'gh', 'workflow', 'view', name, '--web' }, function(_, verr)
              if verr then
                vim.notify('Failed to open workflow.\n' .. (verr or ''), vim.log.levels.ERROR)
              end
            end)
          end),
        },
        win = {
          input = {
            keys = {
              ['<c-s>'] = { 'gh_monitor', mode = { 'n', 'i' }, desc = 'Monitor latest run' },
              ['<c-l>'] = { 'gh_runs', mode = { 'n', 'i' }, desc = 'List recent runs' },
              ['<c-o>'] = { 'gh_browse', mode = { 'n', 'i' }, desc = 'Open on github.com' },
            },
          },
        },
      }
    end)
  end)
end

return M
