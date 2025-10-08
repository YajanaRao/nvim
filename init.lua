require 'options'
require 'keymaps'

--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

--
require('lazy').setup({
  'tpope/vim-sleuth',

  require 'plugins.ui',
  require 'plugins.editor',
  require 'plugins.mini',
  require 'plugins.snacks',

  -- Completion Plugins
  require 'plugins.cmp',

  require 'plugins.lspconfig',
  require 'plugins.snippets',
  require 'plugins.format',

  require 'plugins.comments',

  -- Treesitter
  require 'plugins.treesitter',

  -- require 'plugins.debug',
  require 'plugins.lint',
  require 'plugins.git',

  require 'plugins.ai',
  require 'plugins.colorscheme',
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.cmd.colorscheme 'tokyonight-night'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
