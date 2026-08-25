#!/usr/bin/env bash
# bootstrap.sh — install all tools assumed by the dotfiles
# Safe to re-run: skips anything already present.

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

green() { printf '\033[1;32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%b\033[0m\n' "$*"; }
blue() { printf '\033[1;34m%b\033[0m\n' "$*"; }

# macOS-only bits are gated on this. Kept as one flag rather than repeated
# `uname` calls so the verification pass at the bottom agrees with the install
# section by construction.
IS_MACOS=false
[[ "$(uname -s)" == "Darwin" ]] && IS_MACOS=true

brew_install() {
    local pkg="$1"
    if brew list --formula "$pkg" &>/dev/null; then
        yellow "  brew: $pkg already installed, skipping"
    else
        green "  brew: installing $pkg"
        brew install "$pkg"
    fi
}

# Install only when the command is genuinely absent, whatever provides it.
#
# brew_install asks `brew list`, which only knows brew's own packages, so it
# installs a second copy alongside anything the system already ships. For tmux
# that means two binaries on PATH and a client and server that can disagree
# about version and socket. The same trap is one step away for anything
# installable by more than one route.
#
# Second argument is the formula when it differs from the binary, e.g.
# `ensure_command rg ripgrep`.
ensure_command() {
    local cmd="$1" formula="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        yellow "  $cmd already present ($(command -v "$cmd")), skipping"
    else
        green "  brew: installing $formula"
        brew install "$formula"
    fi
}

# Casks are macOS-only — linuxbrew rejects --cask outright — so every call is
# gated on IS_MACOS by the caller. Mirrors brew_install so a re-run is quiet.
cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null; then
        yellow "  cask: $pkg already installed, skipping"
    else
        green "  cask: installing $pkg"
        brew install --cask "$pkg"
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

    # The installer prints instructions for adding brew to a shell profile and
    # then leaves; it does not touch PATH for the shell running this script. Its
    # location is on no default PATH — /opt/homebrew/bin on Apple silicon,
    # /home/linuxbrew/.linuxbrew/bin on Linux — so without this the very next
    # brew_install call fails and `set -euo pipefail` ends the run, having
    # installed nothing but Homebrew itself.
    #
    # Same three candidates and same order as dot_zshrc, which solves this for
    # interactive shells; the rustup block below sources ~/.cargo/env for the
    # identical reason.
    for _brew in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$_brew" ]]; then
            eval "$("$_brew" shellenv)"
            break
        fi
    done
    unset _brew

    command -v brew &>/dev/null || {
        yellow "  brew installed but not on PATH — cannot continue"
        exit 1
    }
else
    yellow "brew already installed, skipping"
fi

# ── Brew packages ─────────────────────────────────────────────────────────────

blue "\nInstalling brew packages..."

# fonts
# kitty.conf and fontconfig/fonts.conf both name FiraCode Nerd Font, so this is
# a real dependency, not decoration — without it the icons in eza, starship and
# yazi fall back to boxes. It was also the one install in this script that was
# neither guarded against a re-run nor gated by OS: `brew install --cask` fails
# on linuxbrew, and with `set -euo pipefail` that aborted the entire bootstrap
# on the Linux machine before it reached anything else.
#
# The Linux machine still wants the font; it just cannot come from a cask.
# Install it there by hand, or through the distribution's package manager.
if $IS_MACOS; then
    cask_install font-fira-code-nerd-font
fi

# shell
brew_install zsh-autosuggestions
brew_install zsh-syntax-highlighting
brew_install fzf-tab

# prompt & navigation
brew_install starship
brew_install zoxide
brew_install atuin

# file tools
brew_install fd
brew_install fzf
brew_install ripgrep
brew_install eza
brew_install bat
brew_install yazi

# ffmpeg is only here for bin/mkv2mp4, which .chezmoiignore applies on macOS
# alone — the Linux machine is for work and has no use for it. Both sides of
# that decision have to agree, so the verification below is gated the same way.
if $IS_MACOS; then
    brew_install ffmpeg
fi

# editor
brew_install neovim

# lua (for editing neovim config)
brew_install lua-language-server
brew_install stylua

# shell. bash-language-server shells out to shellcheck for its diagnostics,
# so the two go together; nvim's `sh` filetype covers bash and sh alike.
brew_install bash-language-server

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

# terminal multiplexer
# ensure_command, not brew_install: several platforms ship tmux already, and a
# brew copy alongside it has caused version and socket mismatches.
ensure_command tmux

# notes (zk drives plugins/zk.lua and ZK_NOTEBOOK_DIR in dot_zshrc)
ensure_command zk

# dev tooling
brew_install git
brew_install just
brew_install git-cliff
brew_install tree-sitter

# LSP servers that plugins/lsp.lua actually enables. basedpyright below is not
# one of them — it is kept deliberately for CI and `just` checks, where broader
# coverage matters than the editor needs (see the comment in lsp.lua).
ensure_command pyrefly
ensure_command just-lsp

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

# ── atuin history import ──────────────────────────────────────────────────────

blue "\nChecking atuin history..."
# atuin keeps its own SQLite database; `import auto` seeds it from the existing
# shell HISTFILE. Guarded on the database already having rows, because import is
# not idempotent — running it twice duplicates every entry.
ATUIN_DB="$HOME/.local/share/atuin/history.db"
if [[ -s "$ATUIN_DB" ]]; then
    yellow "atuin history db already exists, skipping import"
else
    green "Importing existing shell history into atuin..."
    atuin import auto
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

# ── Verify ────────────────────────────────────────────────────────────────────
# The reason this exists: nothing else checks that bootstrap still provisions
# what the config expects. tmux, zk, pyrefly and just-lsp had all drifted out of
# this script while remaining hard dependencies, and it was invisible because a
# bootstrap is run once per machine, years apart.

blue "\nVerifying..."
missing=()

# Binaries. Formula name and command name differ often enough (neovim/nvim,
# ripgrep/rg) that this list is the command names, deliberately.
for c in tmux nvim zk pyrefly just-lsp ruff fd fzf rg eza bat \
         yazi starship zoxide atuin direnv lazygit just uv tree-sitter \
         git git-cliff shellcheck stylua prettier taplo shfmt biome \
         yamlfmt yamllint lua-language-server bash-language-server; do
    command -v "$c" &>/dev/null || missing+=("$c")
done

# uv tools do not all put a binary on PATH — debugpy is a library — so ask uv.
$IS_MACOS && { command -v ffmpeg &>/dev/null || missing+=("ffmpeg"); }

for t in basedpyright ruff debugpy djlint; do
    uv tool list 2>/dev/null | grep -q "^$t " || missing+=("uv:$t")
done

# Rust components live behind rustup. Test the install location rather than
# PATH: this script sources ~/.cargo/env above, so `command -v rustup` succeeds
# here even when nothing puts ~/.cargo/bin on PATH for a normal shell — which is
# how a complete toolchain sat unreachable and unnoticed. dot_zshrc and
# dot_zshenv are what actually expose it.
if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
    for component in rust-analyzer clippy rustfmt; do
        "$HOME/.cargo/bin/rustup" component list --installed 2>/dev/null \
            | grep -q "^${component}" || missing+=("rustup:$component")
    done
else
    missing+=("rustup")
fi

# zsh plugins are sourced by path and have no binary; dot_zshrc sources these
# unguarded, so a missing one breaks every new shell.
for plug in zsh-autosuggestions/zsh-autosuggestions.zsh \
            zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            fzf-tab/fzf-tab.zsh; do
    [[ -f "$(brew --prefix)/share/$plug" ]] || missing+=("plugin:${plug%%/*}")
done

if (( ${#missing[@]} )); then
    yellow "  missing: ${missing[*]}"
    yellow "  (a new shell may be needed first, or these genuinely failed to install)"
else
    green "  all expected tools present"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

blue "\nAll done. Open a new shell or run: exec zsh"
blue "Then start tmux and press prefix + I to install tmux plugins."
