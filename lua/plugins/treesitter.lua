return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-context',
    },
    build = function()
      require('nvim-treesitter').update(nil, { summary = true })
    end,
    event = { 'BufReadPost', 'BufNewFile', 'VeryLazy' },
    cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall' },
    opts = {
      ensure_installed = { 'bash', 'c', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'html', 'css', 'scss', 'javascript', 'typescript' },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      local TS = require('nvim-treesitter')
      TS.setup(opts)

      -- Install missing parsers
      if TS.get_installed then
        local install = vim.tbl_filter(function(lang)
          return not vim.tbl_contains(TS.get_installed(), lang)
        end, opts.ensure_installed or {})
        if #install > 0 then
          TS.install(install, { summary = true })
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

          -- highlighting
          if opts.highlight and opts.highlight.enable ~= false then
            pcall(vim.treesitter.start, ev.buf)
          end

          -- folds
          vim.wo[0][0].foldmethod = 'expr'
          vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        end,
      })
    end,
  },
}
