vim.pack.add({
  'https://github.com/folke/sidekick.nvim',
}, { load = function() end }) -- register but don't load yet

local sidekick_loaded = false
local function ensure_sidekick()
  if not sidekick_loaded then
    vim.cmd.packadd('sidekick.nvim')
    require('sidekick').setup({
      nes = {
        enabled = true,
        debounce = 100,
      },
      cli = {
        watch = true,
      },
    })
    sidekick_loaded = true
  end
end

-- Initialize sidekick early when copilot attaches so status.get() works
-- in the statusline without waiting for a keypress.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name:lower():find('copilot') then
      ensure_sidekick()
    end
  end,
})

vim.keymap.set('n', '<tab>', function()
  ensure_sidekick()
  if require('sidekick').nes_jump_or_apply() then
    return
  end
  return '<Tab>'
end, { expr = true, desc = 'Apply NES Suggestion' })

-- Insert mode: sidekick NES → mini.snippets jump forward → literal tab.
-- Copilot buffers override this with a buffer-local map set in lspconfig.lua
-- that prepends Copilot inline accept before falling into this same chain.
vim.keymap.set('i', '<Tab>', function()
  ensure_sidekick()
  if require('sidekick').nes_jump_or_apply() then
    return ''
  end
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
    return ''
  end
  return '<Tab>'
end, { expr = true, desc = 'NES / snippet forward / tab' })

vim.keymap.set('i', '<S-Tab>', function()
  if vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
    return ''
  end
  return '<S-Tab>'
end, { expr = true, desc = 'Snippet backward / S-Tab' })

vim.keymap.set('n', '<leader>aa', function()
  ensure_sidekick()
  require('sidekick.cli').toggle()
end, { desc = 'Sidekick Toggle CLI' })

vim.keymap.set('n', '<leader>as', function()
  ensure_sidekick()
  require('sidekick.cli').select()
end, { desc = 'Select CLI' })

vim.keymap.set({ 'x', 'n' }, '<leader>at', function()
  ensure_sidekick()
  require('sidekick.cli').send({ msg = '{this}' })
end, { desc = 'Send This' })

vim.keymap.set('x', '<leader>av', function()
  ensure_sidekick()
  require('sidekick.cli').send({ msg = '{selection}' })
end, { desc = 'Send Visual Selection' })

vim.keymap.set({ 'n', 'x' }, '<leader>ap', function()
  ensure_sidekick()
  require('sidekick.cli').prompt()
end, { desc = 'Sidekick Select Prompt' })

vim.keymap.set({ 'n', 'x', 'i', 't' }, '<c-.>', function()
  ensure_sidekick()
  require('sidekick.cli').focus()
end, { desc = 'Sidekick Switch Focus' })

vim.keymap.set('n', '<leader>ao', function()
  ensure_sidekick()
  require('sidekick.cli').toggle({ name = 'opencode', focus = true })
end, { desc = 'Sidekick Toggle Opencode' })
