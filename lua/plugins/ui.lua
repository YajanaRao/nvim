return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      local trouble = require 'trouble'
      local symbols = trouble.statusline {
        mode = 'lsp_document_symbols',
        groups = {},
        title = false,
        filter = { range = true },
        format = '{kind_icon}{symbol.name:Normal}',
        hl_group = 'lualine_c_normal',
      }
      opts.options = opts.options or {}
      opts.disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } }
      opts.options.globalstatus = true
      opts.sections = opts.sections or {}
      opts.sections.lualine_c = opts.sections.lualine_c or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      opts.sections.lualine_y = opts.sections.lualine_y or {}
      opts.sections.lualine_c = {
        { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
        {
          'filename',
          path = 1,
        },
      }
      opts.sections.lualine_x = {
        {
          require('noice').api.status.message.get_hl,
          cond = require('noice').api.status.message.has,
        },
        {
          require('noice').api.status.command.get,
          cond = require('noice').api.status.command.has,
          color = "DiagnosticWarn",
        },
        {
          require('noice').api.status.mode.get,
          cond = require('noice').api.status.mode.has,
          color = "DiagnosticWarn",
        },
        {
          require('noice').api.status.search.get,
          cond = require('noice').api.status.search.has,
          color = "DiagnosticWarn",
        },
      }
      table.insert(opts.sections.lualine_c, {
        symbols.get,
        cond = symbols.has,
      })
      table.insert(opts.sections.lualine_y, {
        function()
          return ' '
        end,
        color = function()
          local status = require('sidekick.status').get()
          if status then
            -- Use colorscheme's diagnostic line highlight groups
            if status.kind == 'Error' then
              return 'ErrorLine'
            elseif status.busy then
              return 'WarningLine'
            else
              return 'InfoLine'
            end
          end
          return nil
        end,
        cond = function()
          local status = require 'sidekick.status'
          return status.get() ~= nil
        end,
      })
    end,
  },
  {
    'folke/snacks.nvim',
    lazy = false,
    ---@type snacks.Config
    opts = {
      ---@class snacks.dashboard.Config
      ---@field enabled? boolean
      ---@field sections snacks.dashboard.Section
      ---@field formats table<string, snacks.dashboard.Text|fun(item:snacks.dashboard.Item, ctx:snacks.dashboard.Format.ctx):snacks.dashboard.Text>
      dashboard = {
        preset = {
          ---@type fun(cmd:string, opts:table)|nil
          pick = nil,
          ---@type snacks.dashboard.Item[]
          keys = {},
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        -- item field formatters
        formats = {
          icon = function(item)
            if item.file and item.icon == 'file' or item.icon == 'directory' then
              local mini_icons = require 'mini.icons'
              return { mini_icons.get('file', item.file), width = 2, hl = 'icon' }
            end
            return { item.icon, width = 2, hl = 'icon' }
          end,
          footer = { '%s', align = 'center' },
          header = { '%s', align = 'center' },
          file = function(item, ctx)
            local fname = vim.fn.fnamemodify(item.file, ':~')
            fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
            if #fname > ctx.width then
              local dir = vim.fn.fnamemodify(fname, ':h')
              local file = vim.fn.fnamemodify(fname, ':t')
              if dir and file then
                file = file:sub(-(ctx.width - #dir - 2))
                fname = dir .. '/…' .. file
              end
            end
            local dir, file = fname:match '^(.*)/(.+)$'
            return dir and { { dir .. '/', hl = 'dir' }, { file, hl = 'file' } } or { { fname, hl = 'file' } }
          end,
        },
        sections = {
          { section = 'header' },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'startup' },
        },
      },
    },
  },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]rite' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    opts = {
      notify = { enabled = true }, -- Enable notify for noice
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      hover = {
        enabled = true,
        silent = false, -- set to true to not show a message if hover is not available
        view = nil, -- when nil, use defaults from documentation
        ---@type NoiceViewOptions
        opts = {}, -- merged with defaults from documentation
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
  },
}
