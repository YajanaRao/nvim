-- Lazy load nvim-lint on BufReadPre/BufNewFile
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    vim.pack.add({
      'https://github.com/mfussenegger/nvim-lint',
      'https://github.com/rshkarin/mason-nvim-lint',
    })

    -- Auto-install linters via Mason
    require('mason-nvim-lint').setup({
      ensure_installed = { 'markdownlint', 'eslint_d' },
      automatic_installation = true,
    })

    local lint = require('lint')
    lint.linters_by_ft = {
      markdown = { 'markdownlint' },
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        if vim.opt_local.modifiable:get() then
          lint.try_lint()
        end
      end,
    })

    -- Run lint immediately for the current buffer
    if vim.opt_local.modifiable:get() then
      lint.try_lint()
    end
  end,
})
