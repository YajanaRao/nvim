return {
  {
    'folke/sidekick.nvim',
    opts = {
      nes = {
        enabled = true,
        debounce = 100,
      },
      cli = {
        watch = true,
      },
    },
    -- stylua: ignore  
    keys = {
      {
        "<tab>",
        function()
          if require("sidekick").nes_jump_or_apply() then
            return
          end
          return "<Tab>"
        end,
        mode = { "n" },
        expr = true,
        desc = "Apply NES Suggestion",
      },
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        desc = "Select CLI",
      },
      {
        "<leader>at",
        function() require("sidekick.cli").send({ msg = "{this}" }) end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>av",
        function() require("sidekick.cli").send({ msg = "{selection}" }) end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<c-.>",
        function() require("sidekick.cli").focus() end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick Switch Focus",
      },
      {
        "<leader>ao",
        function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end,
        desc = "Sidekick Toggle Opencode",
      },
    },
  },
}
