vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

-- Defer setup until after all plugin/ files have been sourced
vim.schedule(function()
  local trouble_ok, trouble = pcall(require, 'trouble')
  local symbols_component = {}
  if trouble_ok then
    local symbols = trouble.statusline({
      mode = 'lsp_document_symbols',
      groups = {},
      title = false,
      filter = { range = true },
      format = '{kind_icon}{symbol.name:Normal}',
      hl_group = 'lualine_c_normal',
    })
    symbols_component = {
      symbols.get,
      cond = symbols.has,
    }
  end

  require('lualine').setup({
    options = {
      globalstatus = true,
    },
    disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
    sections = {
      lualine_c = {
        { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
        { 'filename', path = 1 },
        symbols_component,
      },
      lualine_x = {
        { 'filetype' },
      },
      lualine_y = {
        {
          function()
            return ' '
          end,
          color = function()
            local ok, status = pcall(require, 'sidekick.status')
            if not ok then return end
            local s = status.get()
            if not s then return end
            return s.kind == 'Error' and 'DiagnosticError' or s.busy and 'DiagnosticWarn'
          end,
          cond = function()
            local ok, status = pcall(require, 'sidekick.status')
            return ok and status.get() ~= nil
          end,
        },
        {
          function()
            local ok, status = pcall(require, 'sidekick.status')
            if not ok then return '' end
            local sessions = status.cli()
            return ' ' .. (#sessions > 1 and #sessions or '')
          end,
          cond = function()
            local ok, status = pcall(require, 'sidekick.status')
            return ok and #status.cli() > 0
          end,
          color = 'Special',
        },
      },
    },
  })
end)
