vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

-- Defer setup until after all plugin/ files have been sourced
vim.schedule(function()
  local trouble_ok, trouble = pcall(require, 'trouble')
  local symbols_component = {}
  if trouble_ok then
    local symbols = trouble.statusline {
      mode = 'lsp_document_symbols',
      groups = {},
      title = false,
      filter = { range = true, ['not'] = { ['symbol.name'] = 'import' } },
      format = '{kind_icon}{symbol.name:Normal}',
      hl_group = 'lualine_c_normal',
    }
    symbols_component = {
      symbols.get,
      cond = symbols.has,
    }
  end

  local function sidekick_status()
    local ok, status = pcall(require, 'sidekick.status')
    return ok and status or nil
  end

  require('lualine').setup {
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
        'searchcount',
        {
          function()
            return ' '
          end,
          color = function()
            local status = sidekick_status()
            if not status then
              return
            end
            local s = status.get()
            if not s then
              return
            end
            return s.kind == 'Error' and 'DiagnosticError' or s.busy and 'DiagnosticWarn' or 'Special'
          end,
          cond = function()
            local status = sidekick_status()
            return status ~= nil and status.get() ~= nil
          end,
        },
        {
          'diagnostics',
          sources = { 'nvim_diagnostic' },
          symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
        },
      },
      lualine_y = {},
    },
  }
end)
