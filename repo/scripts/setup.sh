#!/usr/bin/env bash
#
# Dotfiles setup script for macOS and openSUSE Linux.
# Installs all required tools and applies chezmoi-managed configs.
#
# Tools managed by asdf: neovim, fzf, chezmoi, jq, zellij, golang, python, nodejs, deno
# Tools kept native:     zsh, vim, git, git-lfs, curl, btop, ag, shellcheck,
#                        clipboard utils, flatpak
# Other tools:           Claude Code, OpenCode, bibletui, Iosevka Nerd Font,
#                        oh-my-zsh, Insomnia
#
# Usage:
#   ./repo/scripts/setup.sh              # install everything, prompt interactively for hostname
#   ./repo/scripts/setup.sh <hostname>   # install everything and set hostname
#
# macOS:  run as your normal user (brew must not run as root)
# Linux:  run with sudo (e.g. sudo ./repo/scripts/setup.sh)
#
set -euo pipefail
trap 'error "Script failed at line $LINENO (exit code $?). See log: $LOG_FILE"' ERR

NEW_HOSTNAME="${1:-}"
DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OS="$(uname -s)"
LOG_FILE="$DOTFILES_DIR/setup-$(date +%Y%m%d-%H%M%S).log"

# ---------- helpers ----------

# Log to both terminal (with color) and log file (plain text)
_log() { echo "[$(date +%H:%M:%S)] $1: $2" >> "$LOG_FILE"; }
info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; _log "INFO" "$*"; }
skip()  { printf '\033[1;32m::\033[0m %s (already installed, skipping)\n' "$*"; _log "SKIP" "$*"; }
warn()  { printf '\033[1;33m::\033[0m %s\n' "$*"; _log "WARN" "$*"; }
error() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; _log "ERROR" "$*"; }

# On Linux we run as root via sudo; the real user is $SUDO_USER.
# On macOS we run as the normal user directly.
target_user() {
  if [[ "$OS" == "Darwin" ]]; then
    echo "$USER"
  else
    echo "${SUDO_USER:-$USER}"
  fi
}

target_home() {
  if [[ "$OS" == "Darwin" ]]; then
    dscl . -read "/Users/$(target_user)" NFSHomeDirectory | awk '{print $2}'
  else
    getent passwd "$(target_user)" | cut -d: -f6
  fi
}

# Run a command as the target user. On Linux (running as root) this uses
# su; on macOS the script already runs as the normal user.
# Prepends asdf shims to PATH so asdf-managed tools are available.
run_as_user() {
  local path_prefix='export PATH="$HOME/.asdf/shims:$HOME/.opencode/bin:$HOME/.local/bin:$PATH";'
  local cmd="${1-}"
  if [[ "$OS" == "Darwin" ]]; then
    bash -c "$path_prefix $cmd"
  else
    su - "$(target_user)" -c "$path_prefix $cmd"
  fi
}

# Map asdf plugin name → binary name (for tools where they differ)
asdf_binary_for() {
  case "$1" in
    neovim) echo "nvim"     ;;
    golang) echo "go"       ;;
    nodejs) echo "node"     ;;
    python) echo "python3"  ;;
    *)      echo "$1"       ;;
  esac
}

# Map asdf plugin name → native package name(s) to remove
asdf_native_pkgs_for() {
  if [[ "$OS" == "Darwin" ]]; then
    case "$1" in
      neovim)  echo "neovim"                       ;;
      golang)  echo "go"                           ;;
      nodejs)  echo "node"                         ;;
      python)  echo "python@3"                     ;;
      *)       echo "$1"                           ;;
    esac
  else
    case "$1" in
      neovim)  echo "neovim"                       ;;
      fzf)     echo "fzf fzf-zsh-integration"      ;;
      chezmoi) echo "chezmoi chezmoi-zsh-completion" ;;
      golang)  echo "go"                           ;;
      nodejs)  echo "nodejs-default npm-default"    ;;
      python)  echo "python3"                      ;;
      *)       echo "$1"                           ;;
    esac
  fi
}

# Check if a tool is installed via asdf (check shims dir directly since
# su - login shells don't have asdf shims in PATH)
is_asdf_managed() {
  local shims_dir
  shims_dir="$(target_home)/.asdf/shims"
  [[ -x "$shims_dir/$1" ]]
}

# ---------- preflight ----------

preflight() {
  if [[ "$OS" == "Darwin" ]]; then
    if [[ $EUID -eq 0 ]]; then
      error "Do not run this script as root on macOS. Homebrew refuses to run as root."
      exit 1
    fi
  else
    if [[ $EUID -ne 0 ]]; then
      error "On Linux this script must be run as root (or with sudo)."
      exit 1
    fi
  fi
}

# ---------- hostname ----------

set_hostname() {
  if [[ -z "$NEW_HOSTNAME" ]]; then
    warn "No hostname provided. Current hostname: $(hostname)"
    warn "  Usage: ./repo/scripts/setup.sh <hostname>"
    printf '\033[1;33m::\033[0m Set hostname now? [y/N] '
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      printf '\033[1;33m::\033[0m Enter hostname: '
      read -r NEW_HOSTNAME
      if [[ -z "$NEW_HOSTNAME" ]]; then
        warn "No hostname entered, keeping '$(hostname)'"
        return
      fi
    else
      return
    fi
  fi

  local current
  current="$(hostname)"
  if [[ "$current" == "$NEW_HOSTNAME" ]]; then
    skip "Hostname '$NEW_HOSTNAME'"
    return
  fi

  info "Setting hostname to '$NEW_HOSTNAME'"
  if [[ "$OS" == "Darwin" ]]; then
    sudo scutil --set ComputerName "$NEW_HOSTNAME"
    sudo scutil --set HostName "$NEW_HOSTNAME"
    sudo scutil --set LocalHostName "$NEW_HOSTNAME"
  else
    hostnamectl set-hostname "$NEW_HOSTNAME"
  fi
}

# ---------- native packages ----------

install_packages_brew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Make brew available in the current session
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  local packages=(
    zsh
    vim
    the_silver_searcher
    git
    git-lfs
    curl
    btop
    shellcheck
  )

  local missing=()
  for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      skip "$pkg"
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    info "Installing native packages: ${missing[*]}"
    brew install "${missing[@]}"
  fi

  # GUI apps via cask
  if brew list --cask insomnia &>/dev/null; then
    skip "insomnia"
  else
    info "Installing Insomnia"
    brew install --cask insomnia
  fi
}

install_packages_zypper() {
  local packages=(
    # shell
    zsh

    # editor (fallback; neovim is managed by asdf)
    vim

    # version control
    git
    git-lfs

    # clipboard (zellij-copy helper)
    wl-clipboard    # wl-copy / wl-paste
    xclip
    xsel

    # utilities
    curl
    btop
    unzip
    ShellCheck
    playerctl
    brightnessctl
    polybar

    # build dependencies (needed by asdf to compile python from source)
    gcc
    make
    zlib-devel
    libffi-devel
    libopenssl-devel
    readline-devel
    sqlite3-devel
    libbz2-devel
    xz-devel
    tk-devel

    # flatpak (for GUI apps like Insomnia)
    flatpak
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
    info "Installing native packages: ${missing[*]}"
    zypper install -y "${missing[@]}"
  fi

  # ag (the_silver_searcher) is not in the default openSUSE repos.
  if ! command -v ag &>/dev/null; then
    if command -v opi &>/dev/null; then
      info "Installing the_silver_searcher via opi (OBS)"
      opi the_silver_searcher || warn "Could not install ag via opi. Install it manually."
    else
      warn "ag (the_silver_searcher) is not available in default repos."
      warn "Install 'opi' first (sudo zypper install opi) then run: opi the_silver_searcher"
    fi
  else
    skip "ag"
  fi
}

install_native_packages() {
  info "--- Native packages ---"
  if [[ "$OS" == "Darwin" ]]; then
    install_packages_brew
  else
    install_packages_zypper
  fi
}

# ---------- flatpak ----------

install_flatpak_apps() {
  if [[ "$OS" != "Linux" ]]; then
    return
  fi

  info "Adding Flathub repository"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  if flatpak info rest.insomnia.Insomnia &>/dev/null; then
    skip "Insomnia (flatpak)"
  else
    info "Installing Insomnia via flatpak"
    flatpak install -y flathub rest.insomnia.Insomnia
  fi
}

# ---------- asdf ----------

install_asdf() {
  if command -v asdf &>/dev/null; then
    skip "asdf ($(asdf version))"
    return
  fi

  info "Installing asdf version manager"
  if [[ "$OS" == "Darwin" ]]; then
    brew install asdf
  else
    zypper install -y asdf
  fi
}

install_asdf_tools() {
  info "--- asdf-managed tools ---"

  local tools=(
    neovim
    fzf
    chezmoi
    jq
    zellij
    golang
    python
    nodejs
    deno
  )

  local bin pkgs
  local failed_tools=()

  for tool in "${tools[@]}"; do
    bin="$(asdf_binary_for "$tool")"

    if is_asdf_managed "$bin"; then
      skip "$tool (asdf)"
      continue
    fi

    # Binary exists but is NOT an asdf shim → remove the native package
    if command -v "$bin" &>/dev/null; then
      pkgs="$(asdf_native_pkgs_for "$tool")"
      if [[ -n "$pkgs" ]]; then
        info "$tool: removing native install (will replace with asdf)"
        if [[ "$OS" == "Darwin" ]]; then
          brew uninstall --ignore-dependencies $pkgs 2>/dev/null || true  # word splitting intentional
        else
          zypper remove -y $pkgs 2>/dev/null || true  # word splitting intentional
        fi
      fi
    fi

    info "$tool: adding asdf plugin"
    run_as_user "asdf plugin add $tool 2>/dev/null || true"

    info "$tool: installing latest via asdf"
    if ! run_as_user "asdf install $tool latest && asdf set --home $tool latest"; then
      error "$tool: asdf install failed — skipping"
      failed_tools+=("$tool")
    fi
  done

  if [[ ${#failed_tools[@]} -gt 0 ]]; then
    warn "The following asdf tools failed to install: ${failed_tools[*]}"
  fi

  # Generate zsh completions
  info "asdf: generating zsh completions"
  run_as_user 'mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions" && asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"'
}

# ---------- claude code ----------

install_claude_code() {
  if run_as_user 'command -v claude' &>/dev/null; then
    skip "Claude Code"
    return
  fi

  info "Installing Claude Code CLI"
  if [[ "$OS" == "Darwin" ]]; then
    brew install claude-code
  else
    run_as_user 'curl -fsSL https://claude.ai/install.sh | sh'
  fi
}

# ---------- opencode ----------

install_opencode() {
  if run_as_user 'command -v opencode' &>/dev/null; then
    skip "OpenCode"
  else
    info "Installing OpenCode"
    if [[ "$OS" == "Darwin" ]]; then
      brew install opencode
    else
      run_as_user 'curl -fsSL https://opencode.ai/install | bash'
    fi
  fi

  # Configure OpenCode to use Claude Max subscription via OAuth.
  # This is not officially supported by Anthropic but works via the
  # built-in /connect flow. We check if auth.json already exists to
  # avoid re-prompting on re-runs.
  local auth_file
  auth_file="$(target_home)/.local/share/opencode/auth.json"
  if [[ -f "$auth_file" ]]; then
    skip "OpenCode Claude Max auth"
  else
    info "OpenCode: authenticating with Claude Max subscription"
    info "  A browser window will open — log in with your Claude Max account."
    run_as_user 'opencode auth login'
  fi
}

# ---------- bibletui ----------

install_bibletui() {
  if run_as_user 'command -v bibletui' &>/dev/null; then
    skip "bibletui"
    return
  fi

  info "Installing bibletui (Bible TUI reader)"
  run_as_user 'npm install -g bibletui'
}

# ---------- nerd fonts ----------

install_nerd_fonts() {
  local font_name="Iosevka"
  local font_dir

  if [[ "$OS" == "Darwin" ]]; then
    if brew list --cask font-iosevka-nerd-font &>/dev/null; then
      skip "Nerd Font ($font_name)"
      return
    fi
    info "Installing Nerd Font: $font_name"
    brew install --cask font-iosevka-nerd-font
  else
    font_dir="$(target_home)/.local/share/fonts/NerdFonts"
    if find "$font_dir" -name '*Iosevka*' -print -quit 2>/dev/null | grep -q .; then
      skip "Nerd Font ($font_name)"
    else
      info "Installing Nerd Font: $font_name"
      local tmp_dir
      tmp_dir="$(mktemp -d)"
      local latest_url
      latest_url="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep "browser_download_url.*Iosevka.zip" \
        | head -1 \
        | cut -d '"' -f 4)"

      curl -fsSL -o "$tmp_dir/Iosevka.zip" "$latest_url"
      run_as_user "mkdir -p '$font_dir'"
      unzip -o "$tmp_dir/Iosevka.zip" -d "$font_dir"
      chown -R "$(target_user):" "$font_dir"
      rm -rf "$tmp_dir"

      # Refresh font cache
      fc-cache -f "$font_dir"
    fi

    # Set as default monospace font in XFCE at size 14
    if command -v xfconf-query &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
      info "Setting Iosevka Nerd Font as default monospace (size 14) in XFCE"
      run_as_user 'xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "IosevkaNerdFont 14" --create -t string'
    fi
  fi
}

# ---------- oh-my-zsh ----------

install_oh_my_zsh() {
  local home_dir
  home_dir="$(target_home)"

  if [[ -d "$home_dir/.oh-my-zsh" ]]; then
    skip "oh-my-zsh"
    return
  fi

  info "Installing oh-my-zsh"
  run_as_user 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
}

# ---------- default shell ----------

set_default_shell() {
  local user
  user="$(target_user)"
  local zsh_path
  zsh_path="$(command -v zsh)"

  # Check current shell
  local current_shell
  if [[ "$OS" == "Darwin" ]]; then
    current_shell="$(dscl . -read "/Users/$user" UserShell | awk '{print $2}')"
  else
    current_shell="$(getent passwd "$user" | cut -d: -f7)"
  fi

  if [[ "$current_shell" == */zsh ]]; then
    skip "zsh as default shell"
    return
  fi

  # Ensure zsh is in /etc/shells
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    info "Adding $zsh_path to /etc/shells"
    if [[ "$OS" == "Darwin" ]]; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    else
      echo "$zsh_path" >> /etc/shells
    fi
  fi

  info "Setting zsh as default shell for $user"
  if [[ "$OS" == "Darwin" ]]; then
    chsh -s "$zsh_path"
  else
    chsh -s "$zsh_path" "$user"
  fi
}

# ---------- chezmoi ----------

apply_dotfiles() {
  info "Initializing chezmoi from $DOTFILES_DIR"
  run_as_user "chezmoi init --source='$DOTFILES_DIR' --apply"
}

# ---------- vim plugins ----------

install_vim_plugins() {
  info "Installing vim plugins via vim-plug"
  run_as_user 'nvim --headless +PlugInstall +qall 2>/dev/null' || true
}

# ---------- main ----------

main() {
  echo "=== dotfiles setup — $(date) — $(uname -a) ===" > "$LOG_FILE"
  info "Logging to $LOG_FILE"
  preflight
  set_hostname
  install_native_packages
  install_flatpak_apps
  install_asdf
  install_asdf_tools
  install_claude_code
  install_opencode
  install_bibletui
  install_nerd_fonts
  install_oh_my_zsh
  set_default_shell
  apply_dotfiles
  install_vim_plugins
  info "Done! Log out and back in (or run 'zsh') to start using your new setup."
  info "Full log: $LOG_FILE"
}

main
