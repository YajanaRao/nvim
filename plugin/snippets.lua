local gen_loader = require('mini.snippets').gen_loader

require('mini.snippets').setup({
  snippets = {
    -- Load language-specific files from snippets/<lang>.json in runtimepath
    gen_loader.from_lang(),
  },
})

-- Snippets are available via manual expand (<C-j> by default in mini.snippets).
-- Uncomment to also show them in mini.completion's popup menu:
-- require('mini.snippets').start_lsp_server({ match = false })
