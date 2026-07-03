local gen_loader = require('mini.snippets').gen_loader

require('mini.snippets').setup({
  snippets = {
    -- Load language-specific files from snippets/<lang>.json in runtimepath.
    -- Map React filetypes to also pick up the base ts/js snippet files.
    gen_loader.from_lang({
      lang_patterns = {
        tsx = { 'typescript.json', 'tsx.json' },
        jsx = { 'javascript.json', 'jsx.json' },
      },
    }),
  },
})

-- Snippets are available via manual expand (<C-j> by default in mini.snippets).
-- Uncomment to also show them in mini.completion's popup menu:
-- require('mini.snippets').start_lsp_server({ match = false })
