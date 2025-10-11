local Snacks = require('snacks')

local M = {}

local level_map_rev = {
  trace = vim.log.levels.TRACE,
  debug = vim.log.levels.DEBUG,
  info = vim.log.levels.INFO,
  warn = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

local level_map = {
  [vim.log.levels.TRACE] = 'debug',
  [vim.log.levels.DEBUG] = 'debug',
  [vim.log.levels.INFO] = 'info',
  [vim.log.levels.WARN] = 'warn',
  [vim.log.levels.ERROR] = 'error',
}

function M.notify(msg, level, opts)
  Snacks.notify(msg, { level = level_map[level or vim.log.levels.INFO], title = opts and opts.title or opts and opts.source, timeout = opts and opts.timeout })
end

function M.input(opts, on_confirm)
  Snacks.input({ prompt = opts.prompt, default = opts.default, completion = opts.completion }, on_confirm)
end

function M.select(items, opts, on_choice)
  if Snacks.select then
    Snacks.select({ items = items, kind = opts and opts.kind, format_item = opts and opts.format_item }, function(choice)
      if on_choice then on_choice(choice) end
    end)
  else
    vim.ui.select(items, opts, on_choice)
  end
end

-- Optional: override globals for external plugins to benefit without code changes
vim.notify = M.notify
vim.ui.input = M.input
-- Keep vim.ui.select fallback dynamic; do not override if not desired
-- vim.ui.select = M.select

return M
