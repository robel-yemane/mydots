-- ~/.config/nvim/lua/plugins/python.lua
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      -- Setup pyright for Python
      lspconfig.pyright.setup({
        -- You can add custom settings here
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic", -- Options: "off", "basic", "strict"
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
    end,
  },
}
