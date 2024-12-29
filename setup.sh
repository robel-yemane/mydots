#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# 1. Variables
# ----------------------------------------------------------------------------

# Where you want dotfiles cloned (e.g., ~/.config/dotfiles or ~/dotfiles)
DOTFILES_DIR="$HOME/.config/dotfiles"

# Neovim configuration paths
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_DOTFILES_DIR="$DOTFILES_DIR/nvim"

# We'll store changes to PATH in these environment files
ZPROFILE="$HOME/.zprofile"

# Zsh-related paths
ZSHRC_SRC="$DOTFILES_DIR/shell/zshrc" # Adjust if your .zshrc is elsewhere
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

  # On Apple Silicon, /opt/homebrew/bin is typical. On Intel, /usr/local/bin.
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
# 4. Install Core CLI Dependencies
# ----------------------------------------------------------------------------
echo "[INFO] Installing core CLI dependencies for LazyVim..."
brew install neovim git curl fzf ripgrep fd lazygit tree

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
# 6. Install pipx (for Python packages like pynvim)
# ----------------------------------------------------------------------------
if ! command -v pipx &>/dev/null; then
  echo "[INFO] Installing pipx..."
  brew install pipx
  pipx ensurepath
else
  echo "[INFO] pipx is already installed."
fi

# ----------------------------------------------------------------------------
# 7. Install pynvim via pipx
# ----------------------------------------------------------------------------
echo "[INFO] Installing pynvim with pipx..."
pipx install pynvim || {
  echo "[WARN] pynvim may already be installed or pipx encountered a minor error."
  echo "[WARN] If installed, ignoring the 'No apps associated' message is generally fine."
}

# ----------------------------------------------------------------------------
# 8. Install Additional GUI Applications (Optional)
# ----------------------------------------------------------------------------
echo "[INFO] Installing additional GUI applications..."
brew install --cask ghostty
brew install --cask rectangle

# ----------------------------------------------------------------------------
# 9. Install Oh My Zsh (only if missing)
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
# 10. Backup existing .zshrc and copy from dotfiles
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
# 11. Install zsh-autosuggestions & zsh-syntax-highlighting
# ----------------------------------------------------------------------------
echo "[INFO] Installing zsh-autosuggestions & zsh-syntax-highlighting..."
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting

# ----------------------------------------------------------------------------
# 12. Install LazyVim Starter Configuration
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
# 13. Final Steps
# ----------------------------------------------------------------------------
echo "[INFO] Setup complete! Initializing LazyVim..."

# Start Neovim to allow LazyVim to set up its configuration
echo "[INFO] Launching Neovim to complete setup..."
nvim

echo "[INFO] LazyVim Starter configuration has been successfully installed."
echo "You may need to open a new terminal or run 'source ~/.zprofile' if your PATH changes aren't reflected."
echo "Then run 'nvim' to enjoy your configured LazyVim."
