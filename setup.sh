#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# 1. Variables
# ----------------------------------------------------------------------------

# Where you want dotfiles cloned (e.g. ~/.config/dotfiles or ~/dotfiles)
DOTFILES_DIR="$HOME/.config/dotfiles"

# Where your LunarVim config files reside within your dotfiles repo
LVIM_CONFIG_SRC_DIR="$DOTFILES_DIR/lvim"
LVIM_CONFIG_DEST_DIR="$HOME/.config/lvim"

# Branch of LunarVim to install (optional)
LV_BRANCH="release-1.4/neovim-0.9"

# We'll store changes to PATH in these environment files
ZPROFILE="$HOME/.zprofile"

# Zsh-related paths
ZSHRC_SRC="$DOTFILES_DIR/shell/zshrc"  # Adjust if your .zshrc is elsewhere
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
    } >> "$ZPROFILE"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "[INFO] Homebrew is already installed."
fi

# ----------------------------------------------------------------------------
# 4. Install Core CLI Dependencies
# ----------------------------------------------------------------------------
echo "[INFO] Installing core CLI dependencies for LunarVim..."
brew install neovim node python ripgrep fd

# ----------------------------------------------------------------------------
# 5. Ensure ~/.local/bin in PATH
# ----------------------------------------------------------------------------
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "[INFO] Adding ~/.local/bin to PATH in $ZPROFILE..."
  {
    echo ""
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$ZPROFILE"

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
# 8. Install Additional GUI Applications
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
  unset ZSH  # In case it's set to something
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
# 12. (Optional) Confirm Final Lines in .zshrc
# ----------------------------------------------------------------------------
# Instead of appending lines, we rely on your dotfiles' .zshrc having:
#   source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#   source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# near the end, ensuring they're loaded last.

# ----------------------------------------------------------------------------
# 13. Check if LunarVim is Already Installed
# ----------------------------------------------------------------------------
if command -v lvim &>/dev/null; then
  echo "[INFO] LunarVim is already installed ($(lvim --version | head -n 1))."
  read -rp "Would you like to reinstall/upgrade LunarVim? (y/n) " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "[INFO] Reinstalling LunarVim from branch: $LV_BRANCH"
    bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/$LV_BRANCH/utils/installer/install.sh)
  else
    echo "[INFO] Skipping LunarVim reinstallation."
  fi
else
  echo "[INFO] Installing LunarVim from branch: $LV_BRANCH"
  bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/$LV_BRANCH/utils/installer/install.sh)
fi

# ----------------------------------------------------------------------------
# 14. Copy LunarVim config from dotfiles
# ----------------------------------------------------------------------------
echo "[INFO] Copying your LunarVim config from $LVIM_CONFIG_SRC_DIR to $LVIM_CONFIG_DEST_DIR..."
mkdir -p "$LVIM_CONFIG_DEST_DIR"
cp -r "$LVIM_CONFIG_SRC_DIR/"* "$LVIM_CONFIG_DEST_DIR/"

# ----------------------------------------------------------------------------
# 15. Verification
# ----------------------------------------------------------------------------
echo "[INFO] Verifying installation..."
nvim_version=$(nvim --version 2>/dev/null | head -n 1 || echo "Neovim not found")
lvim_version=$(lvim --version 2>/dev/null | head -n 1 || echo "LunarVim not found")

echo "Neovim version: $nvim_version"
echo "LunarVim version: $lvim_version"

echo "[INFO] Setup complete!"
echo "You may need to open a new terminal or run 'source ~/.zprofile' if your PATH changes aren't reflected."
echo "Then run 'lvim' to enjoy your configured LunarVim."
