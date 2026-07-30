vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

-- Defer setup until after all plugin/ files have been sourced
vim.schedule(function()
  local function sidekick_status()
    local ok, status = pcall(require, 'sidekick.status')
    return ok and status or nil
  end

  require('lualine').setup {
    options = {
      globalstatus = true,
      component_separators = { left = '|', right = '|' },
      section_separators = { left = '', right = '' },
    },
    disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
    sections = {
      -- Loudness gradient: a/z (edges) loud, b/y medium, c/x (center) quiet.
      -- Override default b to drop its diagnostics (moved to y) so it isn't shown twice.
      lualine_b = { 'branch', 'diff' },
      lualine_c = {
        { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
        { 'filename', path = 1 },
      },
      -- Quiet center: transient status indicators only.
      lualine_x = {
        -- Running progress (nvim_echo kind='progress': gh workflow runs, LSP, …).
        {
          function()
            return vim.ui.progress_status()
          end,
          cond = function()
            return vim.ui.progress_status ~= nil and vim.ui.progress_status() ~= ''
          end,
          color = 'DiagnosticInfo',
        },
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
      },
      -- Medium slot near the right edge: diagnostics.
      lualine_y = {
        {
          'diagnostics',
          sources = { 'nvim_diagnostic' },
          symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
        },
      },
    },
  }
end)
