-- Disable mini.completion in picker/special buffers
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'snacks_picker_input', 'snacks_picker', 'prompt' },
  callback = function()
    vim.b.minicompletion_disable = true
  end,
})

-- Filter out noisy 'Text' completions and push snippets to the bottom.
-- Also remove auto-import noise: node built-ins and deep package internals
-- (e.g. node:crypto, winston/lib/winston/transports) that flood results.
local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
local process_items = function(items, base)
  local filtered = vim.tbl_filter(function(item)
    local detail = item.detail or ''
    -- Drop node built-in auto-imports (node:fs, node:crypto, etc.)
    if detail:match('^node:') then return false end
    -- Drop deep package internal paths (e.g. winston/lib/...)
    if detail:match('^%a[%w%-_]*/lib/') then return false end
    return true
  end, items)
  return MiniCompletion.default_process_items(filtered, base, process_items_opts)
end

require('mini.completion').setup({
  lsp_completion = {
    source_func = 'omnifunc',
    auto_setup = false,
    process_items = process_items,
  },
})

-- Set omnifunc for LSP completion only when an LSP client attaches
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
  end,
})

vim.o.complete = '.,w,b,kspell'
vim.o.completeopt = 'menuone,noselect,fuzzy,nosort'
vim.o.completetimeout = 100
