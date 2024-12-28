#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# 1. Variables
# ----------------------------------------------------------------------------

# Where you want dotfiles cloned (e.g. ~/.config/dotfiles or ~/dotfiles)
DOTFILES_DIR="$HOME/.config/dotfiles"

# Where your LunarVim config files reside within your dotfiles repo
LVIM_CONFIG_SRC_DIR="$DOTFILES_DIR/lvim"

# Where to place the LunarVim config on the new system
LVIM_CONFIG_DEST_DIR="$HOME/.config/lvim"

# Specific LunarVim branch (optional)
LV_BRANCH="release-1.4/neovim-0.9"

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

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
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
# 5. Install pipx (for Python packages like pynvim)
# ----------------------------------------------------------------------------
if ! command -v pipx &>/dev/null; then
  echo "[INFO] Installing pipx..."
  brew install pipx
  pipx ensurepath
else
  echo "[INFO] pipx is already installed."
fi

# ----------------------------------------------------------------------------
# 6. Install pynvim via pipx
# ----------------------------------------------------------------------------
echo "[INFO] Installing pynvim with pipx..."
pipx install pynvim || {
  echo "[WARN] pynvim may already be installed or pipx encountered an error."
}

# ----------------------------------------------------------------------------
# 7. Install Additional GUI Applications
# ----------------------------------------------------------------------------
echo "[INFO] Installing additional applications..."
# You can add more GUI apps below as needed:
brew install --cask ghostty

# ----------------------------------------------------------------------------
# 8. Check if LunarVim is Already Installed
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
# 9. Copy LunarVim config from dotfiles
# ----------------------------------------------------------------------------
echo "[INFO] Copying your LunarVim config from $LVIM_CONFIG_SRC_DIR to $LVIM_CONFIG_DEST_DIR..."
mkdir -p "$LVIM_CONFIG_DEST_DIR"
cp -r "$LVIM_CONFIG_SRC_DIR/"* "$LVIM_CONFIG_DEST_DIR/"

# ----------------------------------------------------------------------------
# 10. Verification
# ----------------------------------------------------------------------------
echo "[INFO] Verifying installation..."
nvim_version=$(nvim --version 2>/dev/null | head -n 1 || echo "Neovim not found")
lvim_version=$(lvim --version 2>/dev/null | head -n 1 || echo "LunarVim not found")

echo "Neovim version: $nvim_version"
echo "LunarVim version: $lvim_version"
