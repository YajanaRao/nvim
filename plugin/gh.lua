-- GitHub workflow utilities for Neovim.
--
-- All logic lives in `lua/gh/core.lua` so the exact same implementation backs
-- both this plugin and the standalone terminal launcher (`cli/gh.lua`), which
-- is invoked by the fish `ghb`/`ghwl`/`ghwr`/`ghws` functions.
--
-- Commands: :Ghb :Ghw :Ghwl :Ghwr :Ghws
-- Keymaps:  <leader>ghb <leader>ghw <leader>ghl <leader>ghr <leader>ghs

local gh = require 'gh.core'

vim.api.nvim_create_user_command('Ghb', function(opts)
  gh.ghb(opts.args ~= '' and opts.args or nil)
end, {
  nargs = '?',
  complete = function(arg)
    return vim.tbl_filter(function(t)
      return t:find(arg, 1, true) == 1
    end, gh.VALID_TABS)
  end,
  desc = 'Open GitHub repo tab in browser',
})

vim.api.nvim_create_user_command('Ghwl', function(opts)
  gh.ghwl(tonumber(opts.args))
end, { nargs = '?', desc = 'List runs for a workflow' })

vim.api.nvim_create_user_command('Ghwr', function()
  gh.ghwr()
end, { desc = 'Run a workflow on a branch' })

vim.api.nvim_create_user_command('Ghws', function()
  gh.ghws()
end, { desc = 'Monitor latest workflow run (live)' })

vim.api.nvim_create_user_command('Ghw', function()
  gh.ghw()
end, { desc = 'Workflow picker (run/monitor/list via keys)' })

local map = vim.keymap.set
map('n', '<leader>ghb', function()
  gh.ghb()
end, { desc = 'GitHub Browser Tab' })
-- One picker; act on the selection: <cr> run · <c-s> monitor · <c-l> runs · <c-o> browse.
map('n', '<leader>ghw', function()
  gh.ghw()
end, { desc = 'GitHub Workflows (picker)' })
map('n', '<leader>ghl', function()
  gh.ghwl()
end, { desc = 'GitHub Workflow Runs (list)' })
map('n', '<leader>ghr', function()
  gh.ghwr()
end, { desc = 'GitHub Workflow Run (trigger)' })
map('n', '<leader>ghs', function()
  gh.ghws()
end, { desc = 'GitHub Workflow Status (monitor)' })
