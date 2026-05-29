vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/Bilal2453/luvit-meta',
})

-- lazydev: only needed for lua filetype
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'lua',
  once = true,
  callback = function()
    vim.pack.add({ 'https://github.com/folke/lazydev.nvim' })
    require('lazydev').setup({
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    })
  end,
})

-- Diagnostics
vim.diagnostic.config({
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
})

-- resolve_additional_text_edits=false tells servers to include auto-import
-- edits in the initial completion response rather than deferring to
-- completionItem/resolve, avoiding the timing race in mini.completion.
local capabilities = require('mini.completion').get_lsp_capabilities({
  resolve_additional_text_edits = false,
})
capabilities.workspace = capabilities.workspace or {}
capabilities.workspace.fileOperations = { didRename = true, willRename = true }

vim.lsp.config('*', {
  capabilities = capabilities,
})

-- Copilot LSP
-- editorInfo/editorPluginInfo are required by copilot-language-server to
-- identify the client -- without them every inlineCompletion request fails
-- with -32002 "editorInfo and editorPluginInfo not set".
vim.lsp.config('copilot', {
  cmd = { 'copilot-language-server', '--stdio' },
  root_markers = { '.git' },
  init_options = {
    editorInfo = {
      name = 'Neovim',
      version = tostring(vim.version()),
    },
    editorPluginInfo = {
      name = 'copilot.nvim',
      version = '0.0.1',
    },
  },
})
vim.lsp.enable('copilot')

-- Mason: only used as an installer UI (:MasonInstall, :MasonUpdate)
require('mason').setup()

-- Server configs using native vim.lsp.config + vim.lsp.enable
vim.lsp.config('vtsls', {
  cmd = { 'vtsls', '--stdio' },
  root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json', '.git' },
  capabilities = capabilities,
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
        autoImports = true,
      },
      preferences = {
        includePackageJsonAutoImports = 'auto',
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
    javascript = {
      updateImportsOnFileMove = { enabled = 'always' },
      suggest = {
        completeFunctionCalls = true,
        autoImports = true,
      },
      preferences = {
        includePackageJsonAutoImports = 'auto',
      },
    },
  },
})

vim.lsp.config('cssls', {
  cmd = { 'vscode-css-language-server', '--stdio' },
  root_markers = { 'package.json', '.git' },
  capabilities = capabilities,
})
vim.lsp.config('html', {
  cmd = { 'vscode-html-language-server', '--stdio' },
  root_markers = { 'package.json', '.git' },
  capabilities = capabilities,
})
vim.lsp.config('emmet_ls', {
  cmd = { 'emmet-ls', '--stdio' },
  root_markers = { 'package.json', '.git' },
  filetypes = { 'html', 'css', 'scss', 'javascriptreact', 'typescriptreact' },
  capabilities = capabilities,
})

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  filetypes = { 'lua' },
  capabilities = capabilities,
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
})

vim.lsp.config('tailwindcss', {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  root_markers = { 'tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.cjs', 'tailwind.config.mjs', 'postcss.config.js', 'postcss.config.ts', 'package.json' },
  capabilities = capabilities,
  filetypes = {
    'html',
    'css',
    'scss',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  settings = {
    tailwindCSS = {
      -- Tailwind v4 uses @import "tailwindcss" instead of @tailwind directives
      experimental = {
        classRegex = {
          { 'cva\\(([^)]*)\\)', '["\'`]([^"\'`]*).*?["\'`]' },
          { 'cx\\(([^)]*)\\)', '["\'`]([^"\'`]*).*?["\'`]' },
          { 'cn\\(([^)]*)\\)', '["\'`]([^"\'`]*).*?["\'`]' },
        },
      },
      classAttributes = { 'class', 'className', 'class:list', 'classList', 'ngClass' },
      validate = true,
      lint = {
        cssConflict = 'warning',
        invalidApply = 'error',
        invalidScreen = 'error',
        invalidVariant = 'error',
        invalidConfigPath = 'error',
        invalidTailwindDirective = 'error',
        recommendedVariantOrder = 'warning',
      },
    },
  },
})

vim.lsp.enable({ 'vtsls', 'cssls', 'html', 'emmet_ls', 'lua_ls', 'tailwindcss' })

-- LSP Attach autocmd
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('gK', vim.lsp.buf.signature_help, 'Signature Help (LSP)')
    map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help (LSP)', { 'i' })

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Inlay hints
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      if vim.api.nvim_buf_is_valid(event.buf) and vim.bo[event.buf].buftype == '' then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end
    end

    -- Inline completion (Copilot)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, event.buf) then
      vim.lsp.inline_completion.enable(true, { bufnr = event.buf })

      -- Try Copilot first; fall through to the global <Tab> chain (sidekick
      -- NES → snippet forward → literal tab) when there's no suggestion.
      vim.keymap.set('i', '<Tab>', function()
        if vim.lsp.inline_completion.get() then
          return ''  -- accepted; get() applies it as a side effect
        end
        -- Sidekick NES
        local ok, sidekick = pcall(require, 'sidekick')
        if ok and sidekick.nes_jump_or_apply() then
          return ''
        end
        -- Mini.snippets / vim.snippet jump forward
        if vim.snippet.active({ direction = 1 }) then
          vim.snippet.jump(1)
          return ''
        end
        return '<Tab>'
      end, { buffer = event.buf, expr = true, desc = 'LSP: Copilot → NES → snippet → tab' })

      vim.keymap.set('i', '<M-]>', function()
        vim.lsp.inline_completion.select({ count = 1 })
      end, { buffer = event.buf, desc = 'LSP: Next inline completion' })

      vim.keymap.set('i', '<M-[>', function()
        vim.lsp.inline_completion.select({ count = -1 })
      end, { buffer = event.buf, desc = 'LSP: Prev inline completion' })
    end

    -- Code lens
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
      vim.lsp.codelens.enable(true, { bufnr = event.buf })
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
          vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
        end,
      })
    end
  end,
})
