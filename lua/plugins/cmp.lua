return {
  {
    'saghen/blink.cmp',
    dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    event = { 'InsertEnter', 'CmdlineEnter' }, -- Enhanced: Load on cmdline enter
    version = 'v0.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      snippets = { preset = 'luasnip' },
      keymap = {
        preset = 'default',
      },

      appearance = {
        -- theme support
        use_nvim_cmp_as_default = false,
        nerd_font_variant = 'mono',
      },

      cmdline = {
        enabled = true,
        keymap = { preset = 'cmdline' },
        completion = {
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ':'
            end,
          },
          ghost_text = { enabled = true },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = vim.g.borderStyle },
        },
        menu = {
          border = vim.g.borderStyle,
          draw = {
            treesitter = { 'lsp' },
          },
        },
        ghost_text = {
          enabled = false,
        },
      },

      signature = {
        enabled = true,
        window = { border = vim.g.borderStyle },
      },
    },
    opts_extend = { 'sources.default' },
  },
}
