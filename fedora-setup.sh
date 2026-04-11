#!/usr/bin/env bash
# fedora-setup.sh — Fedora Workstation bootstrap
# Usage: bash fedora-setup.sh
# Idempotent: safe to re-run

set -euo pipefail

log() { echo -e "\n\033[1;34m==> $*\033[0m"; }
ok() { echo -e "\033[1;32m  ✓ $*\033[0m"; }

trap 'echo "Error on line $LINENO"; exit 1' ERR

# ─── DNF config ───────────────────────────────────────────────────────────────
log "Optimising DNF config"
if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
  sudo tee -a /etc/dnf/dnf.conf >/dev/null <<'EOF'
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
keepcache=True
EOF
  ok "DNF config updated"
else
  ok "DNF config already optimised"
fi

# ─── System update ────────────────────────────────────────────────────────────
log "Updating system"
sudo dnf upgrade -y --refresh
ok "System updated"

# ─── RPM Fusion (free only) ───────────────────────────────────────────────────
log "Enabling RPM Fusion"
if ! rpm -qa | grep -q rpmfusion-free-release; then
  sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  ok "RPM Fusion enabled"
else
  ok "RPM Fusion already enabled"
fi

# ─── Core + dev tools ─────────────────────────────────────────────────────────
log "Installing core tools"
CORE_PACKAGES=(
  golang
  neovim
  pipx
  tmux
  kitty
  gh
  jq
  ripgrep
  fd-find
  fzf
  zsh
  openssl-devel
  bzip2-devel
  libffi-devel
)
sudo dnf install -y "${CORE_PACKAGES[@]}"
ok "Core tools installed"

# ─── GNOME tiling extension (Tiling Shell) ────────────────────────────────────
log "Installing Tiling Shell extension"
TILING_SHELL_UUID="tilingshell@ferrarodomenico.com"
TILING_SHELL_DIR="$HOME/.local/share/gnome-shell/extensions/$TILING_SHELL_UUID"

if [[ ! -d "$TILING_SHELL_DIR" ]]; then
  TMP_ZIP=$(mktemp --suffix=.zip)
  curl -fsSL "https://github.com/domferr/tilingshell/releases/latest/download/${TILING_SHELL_UUID}.zip" \
    -o "$TMP_ZIP"
  mkdir -p "$TILING_SHELL_DIR"
  unzip -q "$TMP_ZIP" -d "$TILING_SHELL_DIR"
  rm -f "$TMP_ZIP"

  if [[ -d "$TILING_SHELL_DIR/schemas" ]]; then
    glib-compile-schemas "$TILING_SHELL_DIR/schemas"
  fi

  ok "Tiling Shell installed — log out and enable with:"
  ok "  /usr/bin/gnome-extensions enable $TILING_SHELL_UUID"
else
  ok "Tiling Shell already installed"
fi

# ─── Nerd Font ────────────────────────────────────────────────────────────────
log "Installing JetBrains Mono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [[ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
  TMP_FILE=$(mktemp)
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
    -o "$TMP_FILE"
  tar -xJf "$TMP_FILE" -C "$FONT_DIR"
  rm -f "$TMP_FILE"
  fc-cache -fv >/dev/null
  ok "Font installed"
else
  ok "Font already installed"
fi

# ─── LazyVim ──────────────────────────────────────────────────────────────────
log "Setting up LazyVim"
if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
  ok "LazyVim cloned"
else
  ok "LazyVim already present"
fi

# ─── Flatpak ──────────────────────────────────────────────────────────────────
log "Setting up Flatpak"
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
ok "Flatpak configured"

# ─── Flatpak apps ─────────────────────────────────────────────────────────────
log "Installing Flatpak apps"
FLATPAK_APPS=(
  md.obsidian.Obsidian
  com.bitwarden.desktop
  com.mattjakeman.ExtensionManager
)
for app in "${FLATPAK_APPS[@]}"; do
  if ! flatpak list --app | grep -q "$app"; then
    flatpak install -y --noninteractive flathub "$app"
  else
    ok "$app already installed"
  fi
done
ok "Flatpak apps ready"

# ─── pipx setup ───────────────────────────────────────────────────────────────
log "Ensuring pipx path"
export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath
ok "pipx ready"

# ─── Python tooling ───────────────────────────────────────────────────────────
log "Installing Python tools"
pipx list | grep -q pre-commit || pipx install pre-commit
ok "Python tools ready"

# ─── Shell ────────────────────────────────────────────────────────────────────
log "Setting zsh as default shell"
if [[ "$SHELL" != */zsh ]]; then
  chsh -s "$(which zsh)" || true
  ok "zsh set (logout required)"
else
  ok "zsh already default"
fi

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────
log "Installing Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

log "Installing zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  ok "zsh-autosuggestions installed"
else
  ok "zsh-autosuggestions already installed"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  ok "zsh-syntax-highlighting installed"
else
  ok "zsh-syntax-highlighting already installed"
fi

# ─── Starship ─────────────────────────────────────────────────────────────────
log "Installing Starship prompt"
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  ok "Starship installed"
else
  ok "Starship already installed"
fi

# ─── Starship config ──────────────────────────────────────────────────────────
log "Writing Starship config"
mkdir -p "$HOME/.config"
cat >"$HOME/.config/starship.toml" <<'EOF'
format = """
$directory$git_branch$git_status$golang$python$aws$character
"""

[directory]
truncation_length = 3

[git_status]
ahead = "⇡${count}"
behind = "⇣${count}"
modified = "!${count}"
untracked = "?${count}"
EOF
ok "Starship config written"

# ─── .zshrc — written AFTER Oh My Zsh (which overwrites it on install) ────────
log "Configuring .zshrc"
ZSHRC="$HOME/.zshrc"

sed -i 's/^plugins=(.*)/plugins=(git golang kubectl terraform zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME=""/' "$ZSHRC"

if ! grep -q 'GOPATH' "$ZSHRC"; then
  cat >>"$ZSHRC" <<'EOF'

# Go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
EOF
fi

if ! grep -q 'starship init' "$ZSHRC"; then
  echo '' >>"$ZSHRC"
  echo 'eval "$(starship init zsh)"' >>"$ZSHRC"
fi

ok ".zshrc configured"

# ─── Go environment ───────────────────────────────────────────────────────────
log "Configuring Go environment"
mkdir -p "$HOME/go"/{bin,src,pkg}
ok "Go directories created"

# ─── Summary ──────────────────────────────────────────────────────────────────
echo -e "\n\033[1;32m━━━ Setup complete ━━━\033[0m"
echo "Next steps:"
echo "  1. Log out and back in"
echo "  2. Enable tiling: /usr/bin/gnome-extensions enable tilingshell@ferrarodomenico.com"
echo "  3. Run 'nvim' to initialise LazyVim"
