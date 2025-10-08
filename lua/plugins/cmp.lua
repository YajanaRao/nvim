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
        preset = 'enter',
        ['<C-y>'] = { 'select_and_accept' },
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
          list = {
            selection = { preselect = false },
          },
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ':'
            end,
          },
          ghost_text = { enabled = true },
        },
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == '/' or type == '?' then
            return { 'buffer' }
          end
          -- Commands
          if type == ':' then
            return { 'cmdline' }
          end
          return {}
        end,
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

      signature = { enabled = true, window = { border = vim.g.borderStyle } },
    },
    opts_extend = { 'sources.default' },
  },
}
