#!/usr/bin/env bash
# bootstrap.sh — install all tools assumed by the dotfiles
# Safe to re-run: skips anything already present.

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

green() { printf '\033[1;32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%b\033[0m\n' "$*"; }
blue() { printf '\033[1;34m%b\033[0m\n' "$*"; }

brew_install() {
    local pkg="$1"
    if brew list --formula "$pkg" &>/dev/null; then
        yellow "  brew: $pkg already installed, skipping"
    else
        green "  brew: installing $pkg"
        brew install "$pkg"
    fi
}

uv_tool_install() {
    local pkg="$1"
    if uv tool list 2>/dev/null | grep -q "^$pkg "; then
        yellow "  uv tool: $pkg already installed, skipping"
    else
        green "  uv tool: installing $pkg"
        uv tool install "$pkg"
    fi
}

# ── Homebrew itself ───────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    green "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    yellow "brew already installed, skipping"
fi

# ── Brew packages ─────────────────────────────────────────────────────────────

blue "\nInstalling brew packages..."

# fonts
brew install --cask font-fira-code-nerd-font

# shell
brew_install zsh-autosuggestions
brew_install zsh-syntax-highlighting

# prompt & navigation
brew_install starship
brew_install zoxide

# file tools
brew_install fd
brew_install fzf
brew_install ripgrep
brew_install eza
brew_install bat
brew_install yazi

# editor
brew_install neovim

# lua (for editing neovim config)
brew_install lua-language-server
brew_install stylua

# formatters
brew_install prettier
brew_install taplo
brew_install shfmt
brew_install biome
brew_install yamlfmt

# linters
brew_install yamllint
brew_install shellcheck

# git ui
brew_install lazygit

# shell environment
brew_install direnv

# dev tooling
brew_install just
brew_install git-cliff
brew_install tree-sitter

# ── uv itself ─────────────────────────────────────────────────────────────────

blue "\nChecking uv..."
if ! command -v uv &>/dev/null; then
    green "Installing uv..."
    brew_install uv
else
    yellow "uv already installed, skipping"
fi

# ── uv tools (Python LSP / debug) ─────────────────────────────────────────────

blue "\nInstalling uv tools..."
uv_tool_install basedpyright
uv_tool_install ruff
uv_tool_install debugpy
uv_tool_install djlint

# ── Rust / rustup ─────────────────────────────────────────────────────────────

blue "\nChecking Rust toolchain..."
if ! command -v rustup &>/dev/null; then
    green "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    source "$HOME/.cargo/env"
else
    yellow "rustup already installed, skipping"
fi

for component in rust-analyzer clippy rustfmt; do
    if rustup component list --installed | grep -q "^${component}"; then
        yellow "$component already installed, skipping"
    else
        green "Installing $component..."
        rustup component add "$component"
    fi
done

# ── tmux plugin manager ───────────────────────────────────────────────────────

blue "\nChecking tmux plugin manager (tpm)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    yellow "tpm already present, skipping"
else
    green "Cloning tpm..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ── yazi flavors ──────────────────────────────────────────────────────────────

blue "\nChecking yazi catppuccin flavor..."
YAZI_FLAVOR_DIR="$HOME/.config/yazi/flavors/catppuccin-frappe.yazi"
if [[ -d "$YAZI_FLAVOR_DIR" ]]; then
    yellow "catppuccin-frappe.yazi already installed, skipping"
else
    green "Installing catppuccin-frappe flavor via ya pkg..."
    ya pkg add yazi-rs/flavors:catppuccin-frappe
fi

# ── Done ──────────────────────────────────────────────────────────────────────

blue "\nAll done. Open a new shell or run: exec zsh"
blue "Then start tmux and press prefix + I to install tmux plugins."
