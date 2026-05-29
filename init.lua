vim.loader.enable()

require 'options'
require 'keymaps'

-- mini.nvim must be loaded before plugin/ files run (alphabetical order means
-- cmp.lua and lspconfig.lua load before mini.lua and need mini.completion).

vim.pack.add { 'https://github.com/nvim-mini/mini.nvim' }

vim.opt.runtimepath:prepend '~/Developer/forestflower'
require('forestflower').setup {
  diagnostic_text_highlight = true,
  diagnostic_line_highlight = true,
  transparent_background_level = 2,
}
vim.cmd.colorscheme 'forestflower'

-- Experimental built-in message + cmdline UI (Neovim 0.13+)
require('vim._core.ui2').enable {
  enable = true,
  msg = {
    targets = 'cmd',
    cmd = { height = 0.5 },
    dialog = { height = 0.5 },
    msg = { height = 0.5, timeout = 4000 },
    pager = { height = 1 },
  },
}
