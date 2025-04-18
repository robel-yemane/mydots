#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# 1. Variables
# ----------------------------------------------------------------------------

# Dotfiles and Brewfile paths
DOTFILES_DIR="$HOME/.config/dotfiles"
BREWFILE_PATH="$DOTFILES_DIR/Brewfile"

# Neovim configuration paths
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_DOTFILES_DIR="$DOTFILES_DIR/nvim"
# Python version
DEFAULT_PYTHON_VERSION="3.12.2"

# Environment files
ZPROFILE="$HOME/.zprofile"

# Zsh-related paths
ZSHRC_SRC="$DOTFILES_DIR/shell/zshrc"
ZSHRC_DEST="$HOME/.zshrc"

# ----------------------------------------------------------------------------
# 2. Ensure Command Line Tools are Installed
# ----------------------------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
  echo "[INFO] Installing Xcode Command Line Tools (this may take a while)..."
  xcode-select --install || true
else
  echo "[INFO] Xcode Command Line Tools are already installed. Skipping."
fi

# ----------------------------------------------------------------------------
# 3. Install Homebrew if Missing
# ----------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "[INFO] Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH
  if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    {
      echo ""
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    } >>"$ZPROFILE"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "[INFO] Homebrew is already installed."
fi

# ----------------------------------------------------------------------------
# 4. Install Apps Using Brewfile
# ----------------------------------------------------------------------------
if [ -f "$BREWFILE_PATH" ]; then
  echo "[INFO] Installing packages from Brewfile at $BREWFILE_PATH..."
  brew bundle --file="$BREWFILE_PATH"
else
  echo "[WARN] Brewfile not found at $BREWFILE_PATH. Skipping package installation."
fi

# ----------------------------------------------------------------------------
# 5. Ensure ~/.local/bin in PATH
# ----------------------------------------------------------------------------
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "[INFO] Adding ~/.local/bin to PATH in $ZPROFILE..."
  {
    echo ""
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >>"$ZPROFILE"

  export PATH="$HOME/.local/bin:$PATH"
fi

# ----------------------------------------------------------------------------
# 5.1 Python Environment Setup: pyenv, virtualenv, poetry
# ----------------------------------------------------------------------------

echo "[INFO] Ensuring pyenv, pyenv-virtualenv, and poetry are configured in zshrc..."

if ! grep -q 'PYENV_ROOT' "$ZSHRC_DEST"; then
  {
    echo ''
    echo '# pyenv + pyenv-virtualenv config'
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init --path)"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  } >>"$ZSHRC_DEST"
fi
#
# ----------------------------------------------------------------------------
# 6. Ensure pipx PATH and Install pynvim
# ----------------------------------------------------------------------------
if ! command -v pipx &>/dev/null; then
  echo "[ERROR] pipx not installed. Ensure it's included in your Brewfile."
  exit 1
fi

echo "[INFO] Ensuring pipx PATH setup..."
pipx ensurepath

echo "[INFO] Installing pynvim with pipx..."
pipx install pynvim || {
  echo "[WARN] pynvim may already be installed or pipx encountered a minor error."
  echo "[WARN] If installed, ignoring the 'No apps associated' message is generally fine."
}
# ----------------------------------------------------------------------------
# 6.1 Install Python version and set it globally
# ----------------------------------------------------------------------------

echo "[INFO] Installing and setting default Python via pyenv..."

if ! pyenv versions | grep -q "$DEFAULT_PYTHON_VERSION"; then
  echo "[INFO] Installing Python $DEFAULT_PYTHON_VERSION..."
  pyenv install "$DEFAULT_PYTHON_VERSION"
fi

pyenv global "$DEFAULT_PYTHON_VERSION"

echo "[INFO] Ensuring Poetry environment is ready..."
poetry config virtualenvs.in-project true # optional: keep .venv inside project dir

# ----------------------------------------------------------------------------
# 7. Install Oh My Zsh (only if missing)
# ----------------------------------------------------------------------------
echo "[INFO] Checking for Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "[INFO] Oh My Zsh is already installed. Skipping."
else
  echo "[INFO] Oh My Zsh not found. Installing..."
  unset ZSH # In case it's set to something
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    echo "[WARN] Oh My Zsh installation may have encountered an error."
  }
fi

# ----------------------------------------------------------------------------
# 8. Backup existing .zshrc and copy from dotfiles
# ----------------------------------------------------------------------------
echo "[INFO] Handling ~/.zshrc configuration..."

if [ -f "$ZSHRC_DEST" ]; then
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  echo "[INFO] Found existing ~/.zshrc. Backing it up to ~/.zshrc.bak.$TIMESTAMP"
  mv "$ZSHRC_DEST" "$ZSHRC_DEST.bak.$TIMESTAMP"
fi

if [ -f "$ZSHRC_SRC" ]; then
  echo "[INFO] Copying zshrc from $ZSHRC_SRC to $ZSHRC_DEST"
  cp "$ZSHRC_SRC" "$ZSHRC_DEST"
else
  echo "[WARN] $ZSHRC_SRC does not exist in dotfiles. Skipping copy."
fi

# ----------------------------------------------------------------------------
# 9. Install LazyVim Starter Configuration
# ----------------------------------------------------------------------------
if [ -d "$NVIM_CONFIG_DIR" ]; then
  echo "[INFO] LazyVim is already installed at $NVIM_CONFIG_DIR. Skipping installation."
else
  echo "[INFO] Installing LazyVim Starter Configuration..."

  # Ensure that the dotfiles repository has been cloned
  if [ ! -d "$NVIM_DOTFILES_DIR" ]; then
    echo "[ERROR] Neovim configuration directory not found in dotfiles at $NVIM_DOTFILES_DIR."
    echo "Please ensure that your dotfiles repository contains the 'nvim' folder."
    exit 1
  fi

  # Backup existing Neovim configuration directories (if any)
  echo "[INFO] Backing up existing Neovim configurations (if any)..."
  for dir in "$NVIM_CONFIG_DIR" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
    if [ -d "$dir" ]; then
      mv "$dir" "${dir}.bak.$(date +"%Y%m%d_%H%M%S")"
      echo "[INFO] Backed up $dir to ${dir}.bak.$(date +"%Y%m%d_%H%M%S")"
    fi
  done

  # Copy nvim configuration from dotfiles to ~/.config/nvim
  echo "[INFO] Copying Neovim configuration from dotfiles..."
  cp -R "$NVIM_DOTFILES_DIR/" "$NVIM_CONFIG_DIR/"

  # Launch Neovim to allow LazyVim to set up its configuration
  echo "[INFO] Launching Neovim to complete LazyVim setup..."
  nvim --headless "+Lazy! sync" +qa

  echo "[INFO] LazyVim Starter configuration has been successfully installed."
fi

# ----------------------------------------------------------------------------
# 10. Final Steps
# ----------------------------------------------------------------------------
echo "[INFO] Setup complete! Initializing LazyVim..."

# Start Neovim to allow LazyVim to set up its configuration
echo "[INFO] Launching Neovim to complete setup..."
nvim

echo "[INFO] LazyVim Starter configuration has been successfully installed."
echo "You may need to open a new terminal or run 'source ~/.zprofile' if your PATH changes aren't reflected."
echo "Then run 'nvim' to enjoy your configured LazyVim."
