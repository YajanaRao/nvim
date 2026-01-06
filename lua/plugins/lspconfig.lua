return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'saghen/blink.cmp',
    },

    opts = function()
      ---@class PluginLspOpts
      local ret = {
        -- options for vim.diagnostic.config()
        ---@type vim.diagnostic.Opts
        diagnostics = {
          underline = true,
          severity_sort = true,
          float = { border = 'rounded', source = 'if_many' },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = '󰅚 ',
              [vim.diagnostic.severity.WARN] = '󰀪 ',
              [vim.diagnostic.severity.INFO] = '󰋽 ',
              [vim.diagnostic.severity.HINT] = '󰌶 ',
            },
          },
          virtual_text = {
            source = 'if_many',
            spacing = 4,
            prefix = '●',
            format = function(diagnostic)
              if #diagnostic.message > 100 then
                return diagnostic.message:sub(1, 97) .. '...'
              end
              return diagnostic.message
            end,
          },
        },
        inlay_hints = {
          enabled = true,
          exclude = {},
        },
        codelens = {
          enabled = true,
        },

        servers = {
          vtsls = {
            filetypes = {
              'javascript',
              'javascriptreact',
              'javascript.jsx',
              'typescript',
              'typescriptreact',
              'typescript.tsx',
            },
            settings = {
              complete_function_calls = true,
              vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                  maxInlayHintLength = 30,
                  completion = {
                    enableServerSideFuzzyMatch = true,
                  },
                },
              },
              typescript = {
                updateImportsOnFileMove = { enabled = 'always' },
                suggest = {
                  completeFunctionCalls = true,
                },
                inlayHints = {
                  enumMemberValues = { enabled = true },
                  functionLikeReturnTypes = { enabled = true },
                  parameterNames = { enabled = 'literals' },
                  parameterTypes = { enabled = true },
                  propertyDeclarationTypes = { enabled = true },
                  variableTypes = { enabled = false },
                },
              },
            },
          },
          cssls = {},
          html = {},
          emmet_ls = {},
          lua_ls = {
            settings = {
              Lua = {
                completion = {
                  callSnippet = 'Replace',
                },
                codeLens = {
                  enable = true,
                },
                workspace = {
                  checkThirdParty = false,
                },
              },
            },
          },
        },
      }
      return ret
    end,
    ---@param opts PluginLspOpts
    config = function(_, opts)
      vim.diagnostic.config(opts.diagnostics)

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { 'documentation', 'detail', 'additionalTextEdits' },
      }
      capabilities.workspace = capabilities.workspace or {}
      capabilities.workspace.fileOperations = {
        didRename = true, -- File rename notifications
        willRename = true, -- Pre-rename notifications
      }

      -- Setup Copilot LSP (for inline AI completions)
      vim.lsp.config('copilot', {
        cmd = { 'copilot-language-server', '--stdio' },
        root_markers = { '.git' },
        capabilities = capabilities,
      })
      vim.lsp.enable 'copilot'

      -- Setup Mason
      require('mason').setup()

      require('mason-lspconfig').setup {
        ensure_installed = vim.tbl_keys(opts.servers),
        automatic_enable = true,
      }

      for server_name, server_opts in pairs(opts.servers) do
        local final_opts = vim.tbl_deep_extend('force', {
          capabilities = capabilities,
        }, server_opts)
        vim.lsp.config(server_name, final_opts)
        vim.lsp.enable(server_name)
      end

      -- LSP Attach autocmd
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Keymaps
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gK', vim.lsp.buf.signature_help, 'Signature Help (LSP)')
          map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help (LSP)', { 'i' })

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Inlay hints (reuse opts.inlay_hints)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            if
              vim.api.nvim_buf_is_valid(event.buf)
              and vim.bo[event.buf].buftype == ''
              and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[event.buf].filetype)
            then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
          end

          -- Inline completion (for Copilot AI suggestions)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, event.buf) then
            vim.lsp.inline_completion.enable(true, { bufnr = event.buf })

            -- Keymaps for inline completion (per official Neovim 0.12 docs)
            -- vim.lsp.inline_completion.get() returns false if no completion, else accepts it
            vim.keymap.set('i', '<Tab>', function()
              if not vim.lsp.inline_completion.get() then
                return '<Tab>'
              end
            end, { buffer = event.buf, expr = true, desc = 'LSP: Accept inline completion' })

            -- Cycle through inline completion candidates
            vim.keymap.set('i', '<M-]>', function()
              vim.lsp.inline_completion.select({ count = 1 })
            end, { buffer = event.buf, desc = 'LSP: Next inline completion' })

            vim.keymap.set('i', '<M-[>', function()
              vim.lsp.inline_completion.select({ count = -1 })
            end, { buffer = event.buf, desc = 'LSP: Prev inline completion' })
          end

          -- Code lens
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
            vim.lsp.codelens.refresh { bufnr = event.buf }
            vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
              buffer = event.buf,
              group = vim.api.nvim_create_augroup('codelens-refresh', { clear = false }),
              callback = function()
                vim.lsp.codelens.refresh { bufnr = event.buf }
              end,
            })
          end

          -- Document highlighting
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
