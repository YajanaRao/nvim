return {
  -- lazygit
  {
    'folke/snacks.nvim',
    ---@type snacks.Config
    priority = 1000,
    opts = {
      lazygit = {},
      indent = {},
      image = {},
      bigfiles = {},
      dashboard = {},
      explorer = {
        hidden = true,
        ignored = true,
        replace_netrw = true,
      },
      picker = {
        grep = {
          command = { 'rg', '--vimgrep', '--smart-case' }, -- Use --smart-case or -i
        },
        formatters = {
          file = {
            filename_first = true,
          },
        },
        win = {
          input = {
            keys = {
              ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
              ['s'] = { 'flash' },
            },
          },
        },
        actions = {
          flash = function(picker)
            require('flash').jump {
              pattern = '^',
              label = { after = { 0, 0 } },
              search = {
                mode = 'search',
                exclude = {
                  function(win)
                    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'snacks_picker_list'
                  end,
                },
              },
              action = function(match)
                local idx = picker.list:row2idx(match.pos[1])
                picker.list:_move(idx, true, true)
              end,
            }
          end,
        },
      },
      statuscolumn = {
        left = { 'mark', 'sign' }, -- priority of signs on the left (high to low)
        right = { 'fold', 'git' }, -- priority of signs on the right (high to low)
        folds = {
          open = false,
          git_hl = false,
        },
        git = {
          -- patterns to match Git signs
          patterns = { 'GitSign' },
        },
        refresh = 50, -- refresh at most every 50ms
      },
      words = {},
      scope = {},
    },
    keys = {
      {
        '<leader><space>',
        function()
          Snacks.picker.smart {
            matcher = {
              cwd_bonus = true,
            },
          }
        end,
        desc = 'Smart Find Files',
      },
      {
        '<leader>,',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Buffers',
      },
      {
        '<leader>/',
        function()
          Snacks.picker.grep()
        end,
        desc = 'Grep',
      },
      {
        '<leader>:',
        function()
          Snacks.picker.command_history()
        end,
        desc = 'Command History',
      },
      {
        '<leader>n',
        function()
          Snacks.picker.notifications()
        end,
        desc = 'Notification History',
      },
      -- Git
      {
        '<leader>gf',
        function()
          Snacks.lazygit.log_file()
        end,
        desc = 'Lazygit Current File History',
      },
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gl',
        function()
          Snacks.picker.git_log()
        end,
        desc = 'Git Log (cwd)',
      },
      {
        '<leader>gs',
        function()
          Snacks.picker.git_status()
        end,
        desc = 'Git Status',
      },
      {
        '<leader>gb',
        function()
          Snacks.picker.git_branches()
        end,
        desc = 'Git Branches',
      },

      {
        '<leader>gd',
        function()
          Snacks.picker.git_diff()
        end,
        desc = 'Git Diff (Hunks)',
      },
      -- find
      {
        '<leader>fb',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Buffers',
      },
      {
        '<leader>fc',
        function()
          Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
        end,
        desc = 'Find Config File',
      },
      {
        '<leader>ff',
        function()
          Snacks.picker.files()
        end,
        desc = 'Find Files',
      },
      {
        '<leader>fg',
        function()
          Snacks.picker.git_files()
        end,
        desc = 'Find Git Files',
      },
      {
        '<leader>fp',
        function()
          Snacks.picker.projects()
        end,
        desc = 'Projects',
      },
      {
        '<leader>fr',
        function()
          Snacks.picker.recent()
        end,
        desc = 'Recent',
      },
      {
        '<leader>fe',
        function()
          Snacks.picker.explorer()
        end,
        desc = 'File Explorer',
      },
      -- Search
      {
        '<leader>sb',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Buffers',
      },
      {
        '<leader>sB',
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = 'Grep Open Buffers',
      },
      {
        '<leader>sw',
        function()
          Snacks.picker.grep_word()
        end,
        desc = 'Visual selection or word',
        mode = { 'n', 'x' },
      },
      {
        '<leader>sl',
        function()
          Snacks.picker.lines()
        end,
        desc = 'Buffer Lines',
      },
      {
        '<leader>sg',
        function()
          Snacks.picker.grep {
            regex = false,
          }
        end,
        desc = 'Grep',
      },
      {
        '<leader>s/',
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = 'Grep Open Buffers',
      },
      {
        '<leader>sj',
        function()
          Snacks.picker.jumps()
        end,
        desc = 'Jumps',
      },
      {
        '<leader>sr',
        function()
          Snacks.picker.resume()
        end,
        desc = 'Resume',
      },
      {
        '<leader>sq',
        function()
          Snacks.picker.qflist()
        end,
        desc = 'Quickfix List',
      },
      {
        '<leader>sp',
        function()
          Snacks.picker.cliphist()
        end,
        desc = 'Clipboard History',
      },
      {
        '<leader>sH',
        function()
          Snacks.picker.highlights()
        end,
        desc = 'Highlights',
      },
      -- LSP
      {
        'gd',
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = 'Goto Definition',
      },
      {
        'gD',
        function()
          Snacks.picker.lsp_declarations()
        end,
        desc = 'Goto Declaration',
      },
      {
        'gr',
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = 'References',
      },
      {
        'gI',
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = 'Goto Implementation',
      },
      {
        'gy',
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = 'Goto T[y]pe Definition',
      },
      {
        '<leader>ss',
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = 'LSP [S]ymbols',
      },
      {
        '<leader>sS',
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = 'LSP Workspace Symbols',
      },
      -- Scratch
      {
        '<leader>tt',
        function()
          Snacks.scratch { icon = ' ', name = 'Todo', ft = 'markdown', file = '~/Documents/Notes/To Do/TODO.md' }
        end,
        desc = 'Todo List',
      },
      {
        ']]',
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = 'Next Reference',
        mode = { 'n', 't' },
      },
      {
        '[[',
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = 'Prev Reference',
        mode = { 'n', 't' },
      },
    },
  },
}
