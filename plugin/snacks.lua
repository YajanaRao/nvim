vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('snacks').setup {
  styles = {
    lazygit = { height = 0, width = 0 },
  },
  lazygit = {
    -- lazygit's default nvim edit preset does `--remote-send "q"` to quit
    -- lazygit before opening the file. In a Snacks *float* that keystroke
    -- gets fed back into the lazygit terminal while lazygit is still blocked
    -- on the edit subprocess -> hang. Open in the parent nvim asynchronously
    -- instead (no q round-trip); close the float yourself with `q`.
    config = {
      os = {
        edit = 'nvim --server "$NVIM" --remote-tab-silent {{filename}}',
        editAtLine = 'nvim --server "$NVIM" --remote-tab-silent {{filename}}',
        editAtLineAndWait = 'nvim +{{line}} {{filename}}',
        openDirInEditor = 'nvim --server "$NVIM" --remote-tab-silent {{dir}}',
      },
    },
  },
  indent = {},
  image = {},
  bigfiles = {},
  -- Route vim.notify through Snacks: non-blocking corner toasts (gh workflow
  -- start/success/failure, LSP, etc.), browsable via <leader>n.
  notifier = {
    timeout = 3000,
    style = 'compact',
  },
  dashboard = {
    preset = {
      pick = nil,
      keys = {},
      header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
    },
    formats = {
      icon = function(item)
        if item.file and item.icon == 'file' or item.icon == 'directory' then
          local mini_icons = require 'mini.icons'
          return { mini_icons.get('file', item.file), width = 2, hl = 'icon' }
        end
        return { item.icon, width = 2, hl = 'icon' }
      end,
      footer = { '%s', align = 'center' },
      header = { '%s', align = 'center' },
      file = function(item, ctx)
        local fname = vim.fn.fnamemodify(item.file, ':~')
        fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
        if #fname > ctx.width then
          local dir = vim.fn.fnamemodify(fname, ':h')
          local file = vim.fn.fnamemodify(fname, ':t')
          if dir and file then
            file = file:sub(-(ctx.width - #dir - 2))
            fname = dir .. '/…' .. file
          end
        end
        local dir, file = fname:match '^(.*)/(.+)$'
        return dir and { { dir .. '/', hl = 'dir' }, { file, hl = 'file' } } or { { fname, hl = 'file' } }
      end,
    },
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
    },
  },
  explorer = {
    hidden = true,
    ignored = true,
    replace_netrw = true,
  },
  gh = {},
  picker = {
    grep = {
      command = { 'rg', '--vimgrep', '--smart-case' },
    },
    formatters = {
      file = {
        filename_first = true,
      },
    },
  },
  terminal = {},
  words = {},
  scope = {},
  scroll = {
    animate = {
      duration = { step = 15, total = 250 },
      easing = 'linear',
    },
    spamming = 10,
  },
}

-- Snacks keymaps
local map = vim.keymap.set

-- Smart find / buffers / grep
map('n', '<leader><space>', function()
  Snacks.picker.smart { matcher = { cwd_bonus = true } }
end, { desc = 'Smart Find Files' })
map('n', '<leader>,', function()
  Snacks.picker.buffers()
end, { desc = 'Buffers' })
map('n', '<leader>/', function()
  Snacks.picker.grep()
end, { desc = 'Grep' })
map('n', '<leader>:', function()
  Snacks.picker.command_history()
end, { desc = 'Command History' })
map('n', '<leader>n', function()
  Snacks.picker.notifications()
end, { desc = 'Notification History' })

-- Git
map('n', '<leader>gf', function()
  Snacks.lazygit.log_file()
end, { desc = 'Lazygit Current File History' })
map('n', '<leader>gg', function()
  Snacks.lazygit()
end, { desc = 'Lazygit' })
map('n', '<leader>gl', function()
  Snacks.picker.git_log()
end, { desc = 'Git Log (cwd)' })
map('n', '<leader>gs', function()
  Snacks.picker.git_status()
end, { desc = 'Git Status' })
map('n', '<leader>gb', function()
  Snacks.picker.git_branches()
end, { desc = 'Git Branches' })
map('n', '<leader>gd', function()
  Snacks.picker.git_diff()
end, { desc = 'Git Diff (Hunks)' })
map('n', '<leader>gp', function()
  Snacks.picker.gh_pr()
end, { desc = 'GitHub Pull Requests (open)' })

-- Find
map('n', '<leader>fb', function()
  Snacks.picker.buffers()
end, { desc = 'Buffers' })
map('n', '<leader>fc', function()
  Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
end, { desc = 'Find Config File' })
map('n', '<leader>ff', function()
  Snacks.picker.files()
end, { desc = 'Find Files' })
map('n', '<leader>fg', function()
  Snacks.picker.git_files()
end, { desc = 'Find Git Files' })
map('n', '<leader>fp', function()
  Snacks.picker.projects()
end, { desc = 'Projects' })
map('n', '<leader>fr', function()
  Snacks.picker.recent()
end, { desc = 'Recent' })
map('n', '<leader>fe', function()
  Snacks.picker.explorer()
end, { desc = 'File Explorer' })

-- Search
map('n', '<leader>sB', function()
  Snacks.picker.grep_buffers()
end, { desc = 'Grep Open Buffers' })
map({ 'n', 'x' }, '<leader>sw', function()
  Snacks.picker.grep_word()
end, { desc = 'Visual selection or word' })
map('n', '<leader>sl', function()
  Snacks.picker.lines()
end, { desc = 'Buffer Lines' })
map('n', '<leader>sg', function()
  Snacks.picker.grep { regex = false }
end, { desc = 'Grep' })
map('n', '<leader>s/', function()
  Snacks.picker.grep_buffers()
end, { desc = 'Grep Open Buffers' })
map('n', '<leader>sj', function()
  Snacks.picker.jumps()
end, { desc = 'Jumps' })
map('n', '<leader>sr', function()
  Snacks.picker.resume()
end, { desc = 'Resume' })
map('n', '<leader>sq', function()
  Snacks.picker.qflist()
end, { desc = 'Quickfix List' })
map('n', '<leader>sp', function()
  Snacks.picker.cliphist()
end, { desc = 'Clipboard History' })
map('n', '<leader>sH', function()
  Snacks.picker.highlights()
end, { desc = 'Highlights' })

-- LSP pickers
map('n', 'gd', function()
  Snacks.picker.lsp_definitions()
end, { desc = 'Goto Definition' })
map('n', 'gD', function()
  Snacks.picker.lsp_declarations()
end, { desc = 'Goto Declaration' })
map('n', 'gR', function()
  Snacks.picker.lsp_references()
end, { nowait = true, desc = 'References' })
map('n', 'gI', function()
  Snacks.picker.lsp_implementations()
end, { desc = 'Goto Implementation' })
map('n', 'gy', function()
  Snacks.picker.lsp_type_definitions()
end, { desc = 'Goto T[y]pe Definition' })
map('n', '<leader>ss', function()
  Snacks.picker.lsp_symbols()
end, { desc = 'LSP [S]ymbols' })
map('n', '<leader>sS', function()
  Snacks.picker.lsp_workspace_symbols()
end, { desc = 'LSP Workspace Symbols' })

-- Terminal / Scratch
-- tf = floating terminal, tt = tab terminal, td = todo scratch
map('n', '<leader>tf', function()
  local root = vim.fs.root(0, { '.git' }) or vim.uv.cwd()
  Snacks.terminal.toggle('/opt/homebrew/bin/fish', {
    cwd = root,
    win = { style = 'float' },
  })
end, { desc = 'Terminal Float' })

map('n', '<leader>tt', function()
  -- Only reuse plain :terminal buffers. Sidekick CLIs (sidekick_terminal) and
  -- Snacks terminals/lazygit (snacks_terminal) are also buftype=terminal but
  -- should never be surfaced here.
  local managed = { sidekick_terminal = true, snacks_terminal = true }
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.bo[buf].buftype == 'terminal'
      and not managed[vim.bo[buf].filetype]
      and vim.api.nvim_buf_is_loaded(buf)
    then
      vim.api.nvim_set_current_buf(buf)
      return
    end
  end
  vim.cmd 'terminal /opt/homebrew/bin/fish'
end, { desc = 'Terminal' })

map('n', '<leader>td', function()
  Snacks.scratch { icon = ' ', name = 'Todo', ft = 'text', file = '~/Documents/Notes/To Do/TODO.md' }
end, { desc = 'Todo' })

map({ 'n', 't' }, ']]', function()
  Snacks.words.jump(vim.v.count1)
end, { desc = 'Next Reference' })
map({ 'n', 't' }, '[[', function()
  Snacks.words.jump(-vim.v.count1)
end, { desc = 'Prev Reference' })
