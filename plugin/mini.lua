-- Mock nvim-web-devicons for compatibility with other plugins
package.preload['nvim-web-devicons'] = function()
  require('mini.icons').mock_nvim_web_devicons()
  return package.loaded['nvim-web-devicons']
end

local ai = require('mini.ai')
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    o = ai.gen_spec.treesitter({
      a = { '@block.outer', '@conditional.outer', '@loop.outer' },
      i = { '@block.inner', '@conditional.inner', '@loop.inner' },
    }),
    f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
    c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
    t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
    d = { '%f[%d]%d+' },
    e = {
      { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
      '^().*()$',
    },
    u = ai.gen_spec.function_call(),
    U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }),
  },
})

require('mini.icons').setup()
MiniIcons.tweak_lsp_kind()
require('mini.surround').setup()
require('mini.pairs').setup()
require('mini.bracketed').setup()
require('mini.tabline').setup()
require('mini.move').setup({
  mappings = {
    left = '<M-h>',
    right = '<M-l>',
    down = '<M-j>',
    up = '<M-k>',
    line_left = '<M-h>',
    line_right = '<M-l>',
    line_down = '<M-j>',
    line_up = '<M-k>',
  },
})

local hipatterns = require('mini.hipatterns')
hipatterns.setup({
  highlighters = {
    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

require('mini.files').setup({
  mappings = {
    go_in = 'L',
    go_in_plus = 'l',
  },
})

vim.keymap.set('n', '<leader>e', function()
  MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { desc = 'Open Explorer at current file' })

-- Disabled in favor of vim._core.ui2 (experimental built-in cmdline/message layer)
-- require('mini.cmdline').setup()

-- require('mini.notify').setup()
-- vim.notify = MiniNotify.make_notify()

require('mini.operators').setup()

require('mini.jump').setup()

require('mini.jump2d').setup()

local miniclue = require('mini.clue')
miniclue.setup({
  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = "'" },
    { mode = 'x', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'x', keys = '`' },
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'x', keys = '[' },
    { mode = 'x', keys = ']' },
  },
  clues = {
    { mode = 'n', keys = '<Leader>c', desc = '+Code' },
    { mode = 'x', keys = '<Leader>c', desc = '+Code' },
    { mode = 'n', keys = '<Leader>d', desc = '+Document' },
    { mode = 'n', keys = '<Leader>r', desc = '+Rename' },
    { mode = 'n', keys = '<Leader>s', desc = '+Search' },
    { mode = 'n', keys = '<Leader>w', desc = '+Write' },
    { mode = 'n', keys = '<Leader>t', desc = '+Toggle/Terminal' },
    { mode = 'n', keys = '<Leader>h', desc = '+Git Hunk' },
    { mode = 'v', keys = '<Leader>h', desc = '+Git Hunk' },
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
  window = {
    delay = 300,
    config = { width = 'auto' },
  },
})
