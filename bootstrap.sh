#!/usr/bin/env bash
# bootstrap.sh — install all tools assumed by the dotfiles
#
# Safe to re-run, and meant to be: it skips anything already present and
# installs only the gaps, so pointing it at a half-provisioned machine fills
# that machine in. A failed install does not stop the run — it is recorded,
# the remaining installs still happen, and the script exits non-zero naming
# what failed. See record_failure below.

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

green() { printf '\033[1;32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%b\033[0m\n' "$*"; }
blue() { printf '\033[1;34m%b\033[0m\n' "$*"; }

# Install failures are collected, not fatal.
#
# `set -euo pipefail` otherwise means the first failing install ends the run,
# and everything after it never happens — including the verification pass at
# the bottom, which is the part that says what a machine is still missing. That
# is the wrong shape for a script whose whole job is to fill in the gaps on a
# partially set-up machine: one renamed formula or one flaky download should
# not stop the other forty from installing.
#
# This is the same fault the font cask had below, where a `--cask` that
# linuxbrew rejects "aborted the entire bootstrap on the Linux machine before
# it reached anything else". That was fixed for that one line by gating it on
# the OS; this fixes the shape for every install.
#
# Already-present tools were never the problem — they are skipped, and always
# have been. A failed *install* is the thing worth reporting, so it is reported:
# named in the summary, and the run exits non-zero.
failed=()
record_failure() {
    failed+=("$1")
    yellow "  FAILED: $1 (continuing)"
}

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
        brew install "$pkg" || record_failure "brew:$pkg"
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
        brew install "$formula" || record_failure "brew:$formula"
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
        brew install --cask "$pkg" || record_failure "cask:$pkg"
    fi
}

uv_tool_install() {
    local pkg="$1"
    if uv tool list 2>/dev/null | grep -q "^$pkg "; then
        yellow "  uv tool: $pkg already installed, skipping"
    else
        green "  uv tool: installing $pkg"
        uv tool install "$pkg" || record_failure "uv:$pkg"
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

# system monitor
brew_install btop

# data wrangling — the formula is `visidata`, the binary is `vd`
brew_install visidata

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

# rustup installs with --no-modify-path, so ~/.cargo/env is the only thing that
# puts ~/.cargo/bin on PATH — and this script runs under bash, which never
# reads dot_zshenv. Without this, a machine that already has a full Rust
# toolchain looks like one that has none: `command -v rustup` fails and the
# installer runs again over the top of it. Sourcing first is also what makes
# the verification pass's claim below true on every run rather than only on the
# run that installed rustup.
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if ! command -v rustup &>/dev/null; then
    green "Installing rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path; then
        source "$HOME/.cargo/env"
    else
        record_failure "rustup"
    fi
else
    yellow "rustup already installed, skipping"
fi

for component in rust-analyzer clippy rustfmt; do
    if ! command -v rustup &>/dev/null; then
        yellow "rustup unavailable, skipping $component"
    elif rustup component list --installed 2>/dev/null | grep -q "^${component}"; then
        yellow "$component already installed, skipping"
    else
        green "Installing $component..."
        rustup component add "$component" || record_failure "rustup:$component"
    fi
done

# ── codelldb (Rust debug adapter) ─────────────────────────────────────────────

blue "\nChecking codelldb..."
# rustaceanvim needs a DAP adapter, and codelldb is the one to give it. The
# alternative, lldb-dap, is driven through rustaceanvim's runInTerminal path,
# which hangs on both machines (see the comment in lua/plugins/rust.lua);
# codelldb is detected as a `server` adapter, which never goes near it.
#
# There is no formula for it — upstream ships a VS Code .vsix, which is a zip —
# so this unpacks a pinned release rather than tracking latest, the same
# relationship package.toml has with yazi's flavors.
CODELLDB_VERSION="1.12.3"
CODELLDB_DIR="$HOME/.local/opt/codelldb"
if [[ -x "$CODELLDB_DIR/extension/adapter/codelldb" ]]; then
    yellow "codelldb already installed, skipping"
else
    case "$(uname -s)-$(uname -m)" in
        Darwin-arm64) CODELLDB_ARCH="darwin-arm64" ;;
        Darwin-x86_64) CODELLDB_ARCH="darwin-x64" ;;
        Linux-aarch64) CODELLDB_ARCH="linux-arm64" ;;
        Linux-x86_64) CODELLDB_ARCH="linux-x64" ;;
        *) CODELLDB_ARCH="" ;;
    esac
    if [[ -z "$CODELLDB_ARCH" ]]; then
        yellow "no codelldb build for $(uname -s)-$(uname -m), skipping"
    else
        green "Installing codelldb $CODELLDB_VERSION ($CODELLDB_ARCH)..."
        # Explicit template rather than `mktemp -t codelldb`. BSD mktemp
        # treats the -t argument as a prefix and appends its own X's; GNU
        # requires the template to carry them and fails on one that does not.
        # This form means the same thing to both.
        CODELLDB_VSIX="$(mktemp "${TMPDIR:-/tmp}/codelldb.XXXXXX").vsix"
        mkdir -p "$CODELLDB_DIR"
        if curl -fsSL -o "$CODELLDB_VSIX" \
                "https://github.com/vadimcn/codelldb/releases/download/v${CODELLDB_VERSION}/codelldb-${CODELLDB_ARCH}.vsix" \
           && unzip -q -o "$CODELLDB_VSIX" -d "$CODELLDB_DIR"; then
            # The zip does not preserve the execute bit on every platform.
            chmod +x "$CODELLDB_DIR/extension/adapter/codelldb" \
                     "$CODELLDB_DIR"/extension/lldb/bin/* 2>/dev/null || true
        else
            record_failure "codelldb"
        fi
        rm -f "$CODELLDB_VSIX"
    fi
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
    atuin import auto || record_failure "atuin:import"
fi

# ── yazi flavors ──────────────────────────────────────────────────────────────

blue "\nChecking yazi catppuccin flavor..."
YAZI_FLAVOR_DIR="$HOME/.config/yazi/flavors/catppuccin-frappe.yazi"
if [[ -d "$YAZI_FLAVOR_DIR" ]]; then
    yellow "catppuccin-frappe.yazi already installed, skipping"
elif [[ -f "$HOME/.config/yazi/package.toml" ]]; then
    # `install`, not `add`. package.toml is tracked and records a rev, so this
    # checks out the pinned commit rather than whatever is current — the same
    # relationship lazy-lock.json has with :Lazy install. chezmoi apply runs
    # before this script (see README), so the file is already in place.
    green "Installing yazi packages from the pinned package.toml..."
    ya pkg install || record_failure "yazi:packages"
else
    green "Installing catppuccin-frappe flavor via ya pkg..."
    ya pkg add yazi-rs/flavors:catppuccin-frappe || record_failure "yazi:flavor"
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
         yazi btop vd starship zoxide atuin direnv lazygit just uv tree-sitter \
         git git-cliff shellcheck stylua prettier taplo shfmt biome \
         yamlfmt yamllint lua-language-server bash-language-server; do
    command -v "$c" &>/dev/null || missing+=("$c")
done

# Gated on macOS to match the install above, which is gated because
# .chezmoiignore applies bin/mkv2mp4 there alone.
$IS_MACOS && { command -v ffmpeg &>/dev/null || missing+=("ffmpeg"); }

# Ask uv rather than PATH, because the question is who *manages* these. All
# four do put a binary in ~/.local/bin — `uv tool list` names the executables
# each one provides, debugpy's being `debugpy` and `debugpy-adapter` — so
# `command -v` would pass on any binary of that name from any source, including
# one uv has since stopped tracking. `uv tool list` passing is what makes
# `uv tool upgrade` a real statement about these four.
#
# (This comment used to sit above the ffmpeg line and say debugpy was a library
# with no binary. Both halves were wrong.)
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

# ~/bin/codelldb is only a wrapper; it exists whether or not the adapter it
# execs does, so `command -v` would pass on a machine with nothing installed.
[[ -x "$HOME/.local/opt/codelldb/extension/adapter/codelldb" ]] || missing+=("codelldb")

# zsh plugins are sourced by path and have no binary; dot_zshrc sources these
# unguarded, so a missing one breaks every new shell.
for plug in zsh-autosuggestions/zsh-autosuggestions.zsh \
            zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            fzf-tab/fzf-tab.zsh; do
    [[ -f "$(brew --prefix)/share/$plug" ]] || missing+=("plugin:${plug%%/*}")
done

# What .config/i3 launches, on the machine that applies it. None of these come
# from brew — i3 arrives with the distribution and rofi and the browser with its
# package manager — so this reports rather than installs. It is here because the
# i3 config names them and nothing else in this repo would ever notice they were
# absent: a fresh Linux machine gets a window manager config whose terminal,
# launcher and browser may none of them exist.
if ! $IS_MACOS; then
    for c in i3 kitty rofi google-chrome xset; do
        command -v "$c" &>/dev/null || missing+=("i3-dep:$c")
    done
fi

if (( ${#missing[@]} )); then
    yellow "  missing: ${missing[*]}"
    yellow "  (a new shell may be needed first, or these genuinely failed to install)"
else
    green "  all expected tools present"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

# Two different things, reported apart. `missing` is a statement about the
# machine and can be benign — a tool this run installed may only need a new
# shell to appear on PATH. `failed` is a statement about this run: something
# was attempted and did not work, which is the one condition worth a non-zero
# exit. Everything else still got installed, because that is the point.
if (( ${#failed[@]} )); then
    yellow "\nFailed to install: ${failed[*]}"
    yellow "The rest of the run continued; re-run to retry just these."
    blue "\nOpen a new shell or run: exec zsh"
    exit 1
fi

blue "\nAll done. Open a new shell or run: exec zsh"
