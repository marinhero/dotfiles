#!/usr/bin/env bash
#
# bspwm setup script for openSUSE Tumbleweed.
# Installs bspwm, sxhkd, and supporting packages, then deploys
# chezmoi-managed configs and verifies everything is in place.
#
# Usage:
#   sudo ./bspwm-setup.sh
#
# Log file is written to the same directory as this script.
#
set -euo pipefail
trap 'error "Script failed at line $LINENO (exit code $?). See log: $LOG_FILE"' ERR

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"
LOG_FILE="$DOTFILES_DIR/bspwm-setup-$(date +%Y%m%d-%H%M%S).log"

# ---------- helpers ----------

_log() { echo "[$(date +%H:%M:%S)] $1: $2" >> "$LOG_FILE"; }
info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; _log "INFO" "$*"; }
ok()    { printf '\033[1;32m::\033[0m %s\n' "$*"; _log "OK"   "$*"; }
skip()  { printf '\033[1;32m::\033[0m %s (already installed, skipping)\n' "$*"; _log "SKIP" "$*"; }
warn()  { printf '\033[1;33m::\033[0m %s\n' "$*"; _log "WARN" "$*"; }
error() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; _log "ERROR" "$*"; }

target_user() { echo "${SUDO_USER:-$USER}"; }

target_home() { getent passwd "$(target_user)" | cut -d: -f6; }

# Run a command as the target (non-root) user with asdf shims in PATH.
run_as_user() {
  local path_prefix='export PATH="$HOME/.asdf/shims:$HOME/.local/bin:$PATH";'
  su - "$(target_user)" -c "$path_prefix $*"
}

# ---------- preflight ----------

preflight() {
  if [[ "$OS" != "Linux" ]]; then
    error "This script is for Linux only (detected: $OS)."
    exit 1
  fi

  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (or with sudo)."
    exit 1
  fi

  if ! command -v zypper &>/dev/null; then
    error "zypper not found. This script targets openSUSE."
    exit 1
  fi

  info "Preflight checks passed (user=$(target_user), home=$(target_home))"
}

# ---------- packages ----------

install_packages() {
  info "--- Installing bspwm packages ---"

  local packages=(
    bspwm
    bspwm-zsh-completion
    sxhkd
    dmenu
    rofi
    st
    picom
    alacritty
  )

  local missing=()
  for pkg in "${packages[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
      skip "$pkg"
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    info "Installing: ${missing[*]}"
    zypper install -y "${missing[@]}" 2>&1 | tee -a "$LOG_FILE"
  else
    info "All bspwm packages already installed"
  fi
}

# ---------- chezmoi sync ----------

sync_configs() {
  info "--- Syncing configs to chezmoi source ---"

  local chezmoi_src
  chezmoi_src="$(run_as_user 'chezmoi source-path')"

  if [[ -z "$chezmoi_src" ]]; then
    error "Could not determine chezmoi source path"
    exit 1
  fi

  info "Chezmoi source: $chezmoi_src"

  # Ensure chezmoi is initialized
  if [[ ! -d "$chezmoi_src" ]]; then
    info "Initializing chezmoi"
    run_as_user "chezmoi init"
  fi

  # bspwm config
  local src_bspwm="$DOTFILES_DIR/dot_config/bspwm"
  local dst_bspwm="$chezmoi_src/dot_config/bspwm"

  if [[ ! -d "$src_bspwm" ]]; then
    error "bspwm config not found at $src_bspwm"
    error "Expected: $src_bspwm/executable_bspwmrc"
    exit 1
  fi

  run_as_user "mkdir -p '$dst_bspwm'"
  cp -v "$src_bspwm"/* "$dst_bspwm/" 2>&1 | tee -a "$LOG_FILE"
  chown -R "$(target_user):" "$dst_bspwm"
  ok "bspwm config synced to chezmoi source"

  # sxhkd config
  local src_sxhkd="$DOTFILES_DIR/dot_config/sxhkd"
  local dst_sxhkd="$chezmoi_src/dot_config/sxhkd"

  if [[ ! -d "$src_sxhkd" ]]; then
    error "sxhkd config not found at $src_sxhkd"
    error "Expected: $src_sxhkd/sxhkdrc"
    exit 1
  fi

  run_as_user "mkdir -p '$dst_sxhkd'"
  cp -v "$src_sxhkd"/* "$dst_sxhkd/" 2>&1 | tee -a "$LOG_FILE"
  chown -R "$(target_user):" "$dst_sxhkd"
  ok "sxhkd config synced to chezmoi source"

  # rofi config
  local src_rofi="$DOTFILES_DIR/dot_config/rofi"
  local dst_rofi="$chezmoi_src/dot_config/rofi"

  if [[ -d "$src_rofi" ]]; then
    run_as_user "mkdir -p '$dst_rofi'"
    cp -v "$src_rofi"/* "$dst_rofi/" 2>&1 | tee -a "$LOG_FILE"
    chown -R "$(target_user):" "$dst_rofi"
    ok "rofi config synced to chezmoi source"
  fi
}

# ---------- chezmoi apply ----------

apply_configs() {
  info "--- Applying configs via chezmoi ---"

  run_as_user "chezmoi apply ~/.config/bspwm" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/bspwm"

  run_as_user "chezmoi apply ~/.config/sxhkd" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/sxhkd"

  run_as_user "chezmoi apply ~/.config/rofi" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/rofi"

  # Deploy sxhkd-help script
  run_as_user "chezmoi apply ~/.local/bin/sxhkd-help" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.local/bin/sxhkd-help"
}

# ---------- verify ----------

verify() {
  info "--- Verifying installation ---"

  local home_dir
  home_dir="$(target_home)"
  local pass=0
  local fail=0

  # Check binaries
  for bin in bspwm bspc sxhkd dmenu rofi st picom alacritty; do
    if command -v "$bin" &>/dev/null; then
      ok "binary: $bin ($(command -v "$bin"))"
      ((pass++))
    else
      warn "binary: $bin NOT FOUND"
      ((fail++))
    fi
  done

  # Check bspwmrc exists and is executable
  local bspwmrc="$home_dir/.config/bspwm/bspwmrc"
  if [[ -x "$bspwmrc" ]]; then
    ok "config: $bspwmrc (executable)"
    ((pass++))
  elif [[ -f "$bspwmrc" ]]; then
    warn "config: $bspwmrc exists but is NOT executable"
    ((fail++))
  else
    warn "config: $bspwmrc NOT FOUND"
    ((fail++))
  fi

  # Check sxhkdrc exists
  local sxhkdrc="$home_dir/.config/sxhkd/sxhkdrc"
  if [[ -f "$sxhkdrc" ]]; then
    ok "config: $sxhkdrc"
    ((pass++))
  else
    warn "config: $sxhkdrc NOT FOUND"
    ((fail++))
  fi

  # Check bspwm session file exists (so it appears in display manager)
  if [[ -f /usr/share/xsessions/bspwm.desktop ]]; then
    ok "session: /usr/share/xsessions/bspwm.desktop"
    ((pass++))
  else
    warn "session: bspwm.desktop not found in /usr/share/xsessions/"
    warn "  You may need to create it or select bspwm another way."
    ((fail++))
  fi

  info "Verification: $pass passed, $fail warnings"
}

# ---------- main ----------

main() {
  echo "=== bspwm setup — $(date) — $(uname -a) ===" > "$LOG_FILE"
  info "Logging to $LOG_FILE"

  preflight
  install_packages
  sync_configs
  apply_configs
  verify

  echo "" | tee -a "$LOG_FILE"
  info "================================================"
  info "  bspwm setup complete!"
  info "================================================"
  info ""
  info "Next steps:"
  info "  1. Log out of your current session"
  info "  2. At the login screen, select 'bspwm' as your session"
  info "  3. Log back in"
  info ""
  info "Key bindings:"
  info "  super + /            → keybinding cheatsheet (rofi)"
  info "  super + Return       → terminal (alacritty)"
  info "  super + shift+Return → terminal (st)"
  info "  super + d            → app launcher (rofi)"
  info "  super + space        → window switcher (rofi)"
  info "  super + {h,j,k,l}   → focus window"
  info "  super + {1-9,0}     → switch desktop"
  info "  super + shift + w    → kill window"
  info "  super + alt + r      → restart bspwm"
  info "  super + Escape       → reload keybindings"
  info ""
  info "Full log: $LOG_FILE"
}

main
