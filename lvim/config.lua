-- General settings
lvim.log.level = "warn"
lvim.format_on_save.enabled = false
lvim.colorscheme = "lunar"

-- Set spell checking language to British English
vim.o.spelllang = "en_gb"
-- Leader key
lvim.leader = ";"

-- Direct Key Bindings
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"                  -- Save file
lvim.keys.normal_mode["<C-g>"] = "<cmd>Telescope live_grep<cr>"  -- Live Grep
lvim.keys.normal_mode["<C-f>"] = "<cmd>Telescope find_files<cr>" -- Find Files
lvim.keys.normal_mode["<Tab>"] = ":BufferLineCycleNext<cr>"      -- Next buffer
lvim.keys.normal_mode["<S-Tab>"] = ":BufferLineCyclePrev<cr>"    -- Previous buffer

-- Search Keybindings (Optional in which_key)
lvim.builtin.which_key.mappings["s"] = {
  name = "+Search",
  g = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
  f = { "<cmd>Telescope find_files<cr>", "Find Files" }
}

-- Trouble Keybindings
lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  r = { "<cmd>Trouble lsp_references<cr>", "References" },
  f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
  d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
  l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
}
-- Plugin Settings
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

-- Treesitter Configuration
lvim.builtin.treesitter.ensure_installed = {
  "bash", "javascript", "json", "yaml", "python", "css", "go"
}
lvim.builtin.treesitter.ignore_install = {}
lvim.builtin.treesitter.highlight.enable = true

-- Ensure LSP config is set up properly for different language servers
local lspconfig = require('lspconfig')

-- Python LSP (Pyright)
lspconfig.pyright.setup({
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- Adjust type checking level
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- JavaScript/TypeScript LSP (TSServer)
lspconfig.tsserver.setup({
  -- Add settings here if needed
})

-- Go LSP (gopls)
lspconfig.gopls.setup({
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        unreachable = true,
      },
    },
  },
})
