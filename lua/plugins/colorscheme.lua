return {
  -- { 'rose-pine/neovim', name = 'rose-pine' },
  {
    'folke/tokyonight.nvim',
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    'YajanaRao/forestflower',
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function()
      require('forestflower').setup {
        flavour = 'night',
        italics = true,
      }
    end,
  },
}
