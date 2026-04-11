#!/usr/bin/env bash
# fedora-debloat.sh — high ROI, low-risk cleanup
# Usage:
#   bash fedora-debloat.sh preview
#   bash fedora-debloat.sh apply
set -euo pipefail

log() { echo -e "\n\033[1;34m==> $*\033[0m"; }
ok() { echo -e "\033[1;32m  ✓ $*\033[0m"; }
info() { echo -e "  \033[1;33m~ $*\033[0m"; }

trap 'echo "Error on line $LINENO"; exit 1' ERR

MODE="${1:-apply}"

# ─── Packages to remove ───────────────────────────────────────────────────────
REMOVE_EXACT=(
  # Media / consumer apps
  cheese
  totem-video-thumbnailer
  decibels
  showtime
  loupe
  rygel
  sushi
  # VM guest agents (bare metal)
  hyperv-daemons
  open-vm-tools-desktop
  virtualbox-guest-additions
  spice-vdagent
  spice-webdavd
  qemu-guest-agent
  # Input methods
  ibus-anthy
  ibus-chewing
  ibus-hangul
  ibus-libpinyin
  ibus-m17n
  ibus-typing-booster
  # Printing
  cups
  cups-browsed
  cups-filters
  cups-pk-helper
  gutenprint
  gutenprint-cups
  hplip
  system-config-printer-udev
  # GNOME apps
  gnome-calendar
  gnome-clocks
  gnome-color-manager
  gnome-characters
  gnome-epub-thumbnailer
  gnome-browser-connector
  gnome-initial-setup
  gnome-classic-session
  gnome-remote-desktop
  gnome-user-share
  baobab
  # Misc
  words
  gamemode
  fpaste
  mediawriter
  lrzsz
  unoconv
  paps
  mpage
  abrt-cli
  abrt-desktop
)

REMOVE_GLOBS=(
  "libreoffice*"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────
is_installed() {
  rpm -q "$1" &>/dev/null
}

glob_matches() {
  local prefix="${1//\*/}"
  rpm -qa | grep "^${prefix}" || true
}

# ─── Preview ──────────────────────────────────────────────────────────────────
if [[ "$MODE" == "preview" ]]; then
  log "Preview mode (no changes applied)"

  echo -e "\nExact packages:"
  for pkg in "${REMOVE_EXACT[@]}"; do
    if is_installed "$pkg"; then
      info "Would remove: $pkg"
    else
      ok "Not installed: $pkg"
    fi
  done

  echo -e "\nWildcard packages:"
  for glob in "${REMOVE_GLOBS[@]}"; do
    matches=$(glob_matches "$glob")
    if [[ -n "$matches" ]]; then
      while IFS= read -r match; do
        info "Would remove: $match"
      done <<<"$matches"
    else
      ok "No matches for: $glob"
    fi
  done

  echo -e "\nRun without arguments to apply: bash fedora-debloat.sh"
  exit 0
fi

# ─── Confirm ──────────────────────────────────────────────────────────────────
read -rp "Proceed with removal? [y/N]: " confirm
[[ "${confirm,,}" == "y" ]] || exit 0

# ─── Remove exact packages ────────────────────────────────────────────────────
log "Removing packages"
for pkg in "${REMOVE_EXACT[@]}"; do
  if is_installed "$pkg"; then
    sudo dnf remove -y "$pkg"
    ok "Removed $pkg"
  else
    ok "Not installed — $pkg"
  fi
done

# ─── Remove glob packages ─────────────────────────────────────────────────────
log "Removing LibreOffice"
for glob in "${REMOVE_GLOBS[@]}"; do
  matches=$(glob_matches "$glob")
  if [[ -n "$matches" ]]; then
    mapfile -t pkg_array <<<"$matches"
    sudo dnf remove -y "${pkg_array[@]}"
    ok "Removed: ${pkg_array[*]}"
  else
    ok "No matches for: $glob"
  fi
done

# ─── Cleanup ──────────────────────────────────────────────────────────────────
log "Cleaning unused dependencies"
sudo dnf autoremove -y
ok "Autoremove complete"

log "Cleaning Flatpak runtimes"
flatpak uninstall -y --unused || true
ok "Flatpak cleanup complete"

# ─── Summary ──────────────────────────────────────────────────────────────────
echo -e "\n\033[1;32m━━━ Debloat complete ━━━\033[0m"
echo "System is now leaner with minimal risk."
echo "Next step: use system for a few days, then iterate."
echo "To restore any package: sudo dnf install <package>"
echo "To preview first next time: bash fedora-debloat.sh preview"
