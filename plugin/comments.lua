-- Defer ts-comments loading to after startup
vim.schedule(function()
  vim.pack.add({ 'https://github.com/folke/ts-comments.nvim' })
  require('ts-comments').setup({})
end)
