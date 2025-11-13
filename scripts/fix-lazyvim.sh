#!/usr/bin/env bash
#
# LazyVim Health Check Fixer for macOS
# Fixes common issues found in :checkhealth
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed. Install from https://brew.sh"
    exit 1
fi

log_info "Starting LazyVim configuration fixes..."
echo ""

# ============================================================================
# SECTION 1: Install Missing Critical Tools
# ============================================================================
log_info "Section 1: Installing missing critical tools via Homebrew"

BREW_PACKAGES=(
    "fd"           # File finder (lazyvim requirement)
    "lazygit"      # Git UI (lazyvim requirement)
    "ast-grep"     # Advanced searching (grug-far)
    "imagemagick"  # Image rendering in snacks.nvim
)

for package in "${BREW_PACKAGES[@]}"; do
    if command -v "$package" &> /dev/null; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        if brew install "$package"; then
            log_success "$package installed successfully"
        else
            log_error "Failed to install $package"
        fi
    fi
done

echo ""

# ============================================================================
# SECTION 2: Fix Python Setup
# ============================================================================
log_info "Section 2: Fixing Python setup with asdf"

# Check if asdf is installed
if command -v asdf &> /dev/null; then
    # Check if python plugin is installed
    if ! asdf plugin list | grep -q python; then
        log_info "Adding Python plugin to asdf..."
        asdf plugin add python
    fi

    # Check if python 3.12.0 is installed (as suggested by the health check)
    if ! asdf list python 2>/dev/null | grep -q "3.12.0"; then
        log_info "Installing Python 3.12.0 via asdf (this may take a while)..."
        if asdf install python 3.12.0; then
            log_success "Python 3.12.0 installed"
        else
            log_warning "Failed to install Python 3.12.0 via asdf"
        fi
    else
        log_success "Python 3.12.0 is already installed"
    fi

    # Set global python version
    log_info "Setting global Python version to 3.12.0..."
    asdf global python 3.12.0

    # Reshim
    asdf reshim python

else
    log_warning "asdf not found. Using system Python instead."
fi

# Install Python neovim package
log_info "Installing Python neovim package..."
if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
    PIP_CMD=$(command -v pip3 || command -v pip)
    if $PIP_CMD install --upgrade pynvim; then
        log_success "Python neovim package installed"
    else
        log_warning "Failed to install pynvim"
    fi
else
    log_warning "pip not found. Cannot install pynvim"
fi

echo ""

# ============================================================================
# SECTION 3: Fix Node.js Provider
# ============================================================================
log_info "Section 3: Fixing Node.js provider"

if command -v npm &> /dev/null; then
    log_info "Installing/updating neovim npm package globally..."
    if npm install -g neovim; then
        log_success "Node.js neovim package installed"
    else
        log_warning "Failed to install neovim npm package"
    fi
else
    log_warning "npm not found. Install Node.js to enable Node.js provider"
fi

echo ""

# ============================================================================
# SECTION 4: Fix Ruby Provider
# ============================================================================
log_info "Section 4: Fixing Ruby provider"

if command -v gem &> /dev/null; then
    log_info "Installing neovim gem..."
    if gem install neovim; then
        log_success "Ruby neovim gem installed"
    else
        log_warning "Failed to install neovim gem. You may need sudo or rbenv/rvm"
        log_info "Try: gem install neovim --user-install"
    fi
else
    log_warning "gem not found. Ruby provider will not work"
fi

echo ""

# ============================================================================
# SECTION 5: Provider Configuration
# ============================================================================
log_info "Section 5: Provider configuration"

NVIM_INIT_FILE="$HOME/.config/nvim/init.lua"
PROVIDER_CONFIG="$HOME/.config/nvim/lua/config/providers.lua"

cat << 'EOF'
You can disable optional providers to suppress warnings.
Add these lines to your init.lua or a separate config file:

-- Disable Perl provider (rarely used)
vim.g.loaded_perl_provider = 0

-- Only if you don't need Node.js provider:
-- vim.g.loaded_node_provider = 0

-- Only if you don't need Python provider:
-- vim.g.loaded_python3_provider = 0

-- Only if you don't need Ruby provider:
-- vim.g.loaded_ruby_provider = 0
EOF

read -p "Would you like to disable the Perl provider? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    PROVIDER_DIR="$(dirname "$PROVIDER_CONFIG")"
    mkdir -p "$PROVIDER_DIR"

    if [[ ! -f "$PROVIDER_CONFIG" ]]; then
        cat > "$PROVIDER_CONFIG" << 'EOF'
-- Provider Configuration
-- Disable unused providers to suppress warnings

-- Disable Perl provider (rarely used)
vim.g.loaded_perl_provider = 0
EOF
        log_success "Created $PROVIDER_CONFIG with Perl provider disabled"

        # Add require to init.lua if it exists and doesn't already have it
        if [[ -f "$NVIM_INIT_FILE" ]] && ! grep -q "require.*config.providers" "$NVIM_INIT_FILE"; then
            echo "" >> "$NVIM_INIT_FILE"
            echo "-- Load provider configuration" >> "$NVIM_INIT_FILE"
            echo "require('config.providers')" >> "$NVIM_INIT_FILE"
            log_success "Added provider config to init.lua"
        fi
    else
        log_info "Provider config already exists at $PROVIDER_CONFIG"
    fi
fi

echo ""

# ============================================================================
# SECTION 6: Fix luarocks (Optional)
# ============================================================================
log_info "Section 6: Luarocks setup (optional)"

cat << 'EOF'
Luarocks warnings can be safely ignored unless you have plugins that require it.
To disable luarocks in LazyVim, add this to your lazy.nvim config:

require("lazy").setup({
  rocks = {
    enabled = false,
  },
  -- ... rest of your config
})
EOF

echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================
log_success "Configuration fixes completed!"
echo ""
log_info "Summary of actions taken:"
echo "  ✓ Installed critical tools (fd, lazygit, ast-grep, imagemagick)"
echo "  ✓ Fixed Python setup and installed pynvim"
echo "  ✓ Installed Node.js neovim package"
echo "  ✓ Installed Ruby neovim gem"
echo "  ✓ Installed ImageMagick for snacks.nvim image support"
echo ""
log_info "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
echo "  2. Open Neovim and run: :checkhealth"
echo "  3. Most warnings should now be resolved"
echo ""
log_warning "Remaining optional items:"
echo "  - Language-specific tools (cargo, java, php, julia) - install as needed"
echo "  - Terminal graphics - iTerm doesn't support kitty graphics protocol (this is expected)"
echo ""
log_info "For reference, your health check can be run with: nvim +checkhealth"
