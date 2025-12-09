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
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-y>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
        -- Tab: NES > LSP inline > snippet > fallback
        ['<Tab>'] = {
          function()
            local ok, result = pcall(require('sidekick').nes_jump_or_apply)
            if ok and result then
              return true
            end

            if vim.lsp.inline_completion then
              ok, result = pcall(vim.lsp.inline_completion.get)
              if ok and result then
                pcall(vim.lsp.inline_completion.accept)
                return true
              end
            end

            ok, result = pcall(require, 'luasnip')
            if ok and result.locally_jumpable(1) then
              result.jump(1)
              return true
            end

            return false
          end,
          'fallback',
        },
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
