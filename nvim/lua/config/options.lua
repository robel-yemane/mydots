-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set the leader key to backslash
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "pyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"
-- Set the LSP server for Go
vim.g.lazyvim_go_lsp = "gopls"
vim.g.lazyvim_go_formatter = "gofumpt" -- Choose between "gofumpt" or "goimports"
vim.g.lazyvim_go_linter = "golangci-lint"

-- JSON Configuration
vim.g.lazyvim_json_lsp = "jsonls"

-- Lua Configuration
vim.g.lazyvim_lua_lsp = "lua-language-server"
vim.g.lazyvim_lua_formatter = "stylua"

-- Shell Script Configuration
vim.g.lazyvim_shell_formatter = "shfmt"

-- Terraform Configuration
vim.g.lazyvim_terraform_lsp = "terraform-ls"
vim.g.lazyvim_terraform_linter = "tflint"
