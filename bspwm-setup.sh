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
    playerctl
    brightnessctl
    polybar
    i3lock
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

  # polybar config
  local src_polybar="$DOTFILES_DIR/dot_config/polybar"
  local dst_polybar="$chezmoi_src/dot_config/polybar"

  if [[ ! -d "$src_polybar" ]]; then
    error "polybar config not found at $src_polybar"
    exit 1
  fi

  run_as_user "mkdir -p '$dst_polybar'"
  cp -v "$src_polybar"/* "$dst_polybar/" 2>&1 | tee -a "$LOG_FILE"
  chown -R "$(target_user):" "$dst_polybar"
  ok "polybar config synced to chezmoi source"

  # rofi config
  local src_rofi="$DOTFILES_DIR/dot_config/rofi"
  local dst_rofi="$chezmoi_src/dot_config/rofi"

  if [[ -d "$src_rofi" ]]; then
    run_as_user "mkdir -p '$dst_rofi'"
    cp -v "$src_rofi"/* "$dst_rofi/" 2>&1 | tee -a "$LOG_FILE"
    chown -R "$(target_user):" "$dst_rofi"
    ok "rofi config synced to chezmoi source"
  fi

  # helper scripts (sxhkd-help, st-wrapper, etc.)
  local src_bin="$DOTFILES_DIR/dot_local/bin"
  local dst_bin="$chezmoi_src/dot_local/bin"

  if [[ -d "$src_bin" ]]; then
    run_as_user "mkdir -p '$dst_bin'"
    cp -v "$src_bin"/* "$dst_bin/" 2>&1 | tee -a "$LOG_FILE"
    chown -R "$(target_user):" "$dst_bin"
    ok "helper scripts synced to chezmoi source"
  fi

  # desktop entries (st-wrapper launcher, etc.)
  local src_apps="$DOTFILES_DIR/dot_local/share/applications"
  local dst_apps="$chezmoi_src/dot_local/share/applications"

  if [[ -d "$src_apps" ]]; then
    run_as_user "mkdir -p '$dst_apps'"
    cp -v "$src_apps"/* "$dst_apps/" 2>&1 | tee -a "$LOG_FILE"
    chown -R "$(target_user):" "$dst_apps"
    ok "desktop entries synced to chezmoi source"
  fi
}

# ---------- chezmoi apply ----------

apply_configs() {
  info "--- Applying configs via chezmoi ---"

  run_as_user "chezmoi apply ~/.config/bspwm" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/bspwm"

  run_as_user "chezmoi apply ~/.config/sxhkd" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/sxhkd"

  run_as_user "chezmoi apply ~/.config/polybar" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/polybar"

  run_as_user "chezmoi apply ~/.config/rofi" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.config/rofi"

  # Deploy helper scripts
  run_as_user "chezmoi apply ~/.local/bin/sxhkd-help" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.local/bin/sxhkd-help"

  run_as_user "chezmoi apply ~/.local/bin/st-wrapper" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.local/bin/st-wrapper"

  # Deploy desktop entries
  run_as_user "mkdir -p ~/.local/share/applications"
  run_as_user "chezmoi apply ~/.local/share/applications" 2>&1 | tee -a "$LOG_FILE"
  ok "chezmoi apply ~/.local/share/applications"
}

# ---------- verify ----------

verify() {
  info "--- Verifying installation ---"

  local home_dir
  home_dir="$(target_home)"
  local pass=0
  local fail=0

  # Check binaries
  for bin in bspwm bspc sxhkd dmenu rofi st picom alacritty polybar; do
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

  # Check polybar config exists
  local polybar_config="$home_dir/.config/polybar/config.ini"
  if [[ -f "$polybar_config" ]]; then
    ok "config: $polybar_config"
    ((pass++))
  else
    warn "config: $polybar_config NOT FOUND"
    ((fail++))
  fi

  # Check polybar launch script exists and is executable
  local polybar_launch="$home_dir/.config/polybar/launch.sh"
  if [[ -x "$polybar_launch" ]]; then
    ok "script: $polybar_launch (executable)"
    ((pass++))
  else
    warn "script: $polybar_launch NOT FOUND or not executable"
    ((fail++))
  fi

  # Check rofi config exists
  local rofi_config="$home_dir/.config/rofi/config.rasi"
  if [[ -f "$rofi_config" ]]; then
    ok "config: $rofi_config"
    ((pass++))
  else
    warn "config: $rofi_config NOT FOUND"
    ((fail++))
  fi

  # Check sxhkd-help exists and is executable
  local sxhkd_help="$home_dir/.local/bin/sxhkd-help"
  if [[ -x "$sxhkd_help" ]]; then
    ok "script: $sxhkd_help (executable)"
    ((pass++))
  else
    warn "script: $sxhkd_help NOT FOUND or not executable"
    ((fail++))
  fi

  # Check st-wrapper exists and is executable
  local st_wrapper="$home_dir/.local/bin/st-wrapper"
  if [[ -x "$st_wrapper" ]]; then
    ok "script: $st_wrapper (executable)"
    ((pass++))
  else
    warn "script: $st_wrapper NOT FOUND or not executable"
    ((fail++))
  fi

  # Check st desktop entry exists
  local st_desktop="$home_dir/.local/share/applications/st.desktop"
  if [[ -f "$st_desktop" ]]; then
    ok "desktop: $st_desktop"
    ((pass++))
  else
    warn "desktop: $st_desktop NOT FOUND"
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
  info "Key bindings (super = Cmd-style modifier):"
  info "  super + /            → keybinding cheatsheet"
  info "  super + space        → app launcher (Alfred-style)"
  info "  super + Tab          → window switcher (Cmd+Tab style)"
  info "  super + Return       → terminal (alacritty)"
  info "  super + shift+Return → terminal (st)"
  info "  super + {h,j,k,l}   → focus window (vim-style)"
  info "  super + {1-9,0}     → switch desktop"
  info "  super + w            → close window"
  info "  super + r            → reload keybindings"
  info "  super + shift + r    → restart bspwm"
  info ""
  info "Full log: $LOG_FILE"
}

main
