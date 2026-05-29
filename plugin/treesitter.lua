vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
})

-- Force-load nvim-treesitter plugin files (filetypes.lua, query_predicates.lua, etc.)
-- vim.pack.add uses load=false during init, so these are skipped without this call.
vim.cmd.packadd('nvim-treesitter')

local TS = require('nvim-treesitter')

-- Install missing parsers.
-- get_installed() returns the union of installed parsers + query dirs, so a lang
-- can appear "installed" when only queries exist. Check parser files directly
-- and force-install that split state.
local ensure_installed = {
  'bash', 'c', 'lua', 'luadoc', 'markdown', 'markdown_inline',
  'query', 'vim', 'vimdoc', 'html', 'css', 'scss', 'javascript', 'typescript', 'tsx',
}

if TS.get_installed then
  local config = require('nvim-treesitter.config')
  local missing = vim.tbl_filter(function(lang)
    return vim.uv.fs_stat(vim.fs.joinpath(config.get_install_dir('parser'), lang .. '.so')) == nil
  end, ensure_installed)

  if #missing > 0 then
    TS.install(missing, { force = true, summary = true })
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom_treesitter', { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then
      return
    end

    local has_parser = pcall(vim.treesitter.language.inspect, lang)
    if not has_parser then
      return
    end

    pcall(vim.treesitter.start, ev.buf)

    vim.wo[0][0].foldmethod = 'expr'
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end,
})
