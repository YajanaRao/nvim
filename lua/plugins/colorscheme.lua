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
    opts = {
      diagnostic_text_highlight = true,
      diagnostic_line_highlight = true, -- Enable ErrorLine, WarningLine, InfoLine, HintLine
    },
  },
}
