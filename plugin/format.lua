vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

-- oxfmt is preferred over prettier: ~30x faster, Prettier-compatible output
local js_fmt = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true }

require('conform').setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- LSP formatters for C/C++ tend to disagree with project style
    local lsp = (vim.bo[bufnr].filetype == 'c' or vim.bo[bufnr].filetype == 'cpp') and 'never' or 'fallback'
    return { timeout_ms = 2500, lsp_format = lsp }
  end,
  formatters_by_ft = {
    lua             = { 'stylua' },
    javascript      = js_fmt,
    javascriptreact = js_fmt,
    typescript      = js_fmt,
    typescriptreact = js_fmt,
    json            = js_fmt,
    jsonc           = js_fmt,
    json5           = js_fmt,
    vue             = js_fmt,
    css             = js_fmt,
    scss            = js_fmt,
    less            = js_fmt,
    html            = js_fmt,
    markdown        = js_fmt,
    mdx             = js_fmt,
    yaml            = js_fmt,
    graphql         = js_fmt,
  },
})

vim.keymap.set('n', '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = '[C]ode [F]ormat' })
