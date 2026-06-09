#!/bin/bash
# Regenerate zsh completions that Homebrew upgrades may overwrite

BREW_PREFIX=$(brew --prefix)
ZSH_SITE_FUNCTIONS="$BREW_PREFIX/share/zsh/site-functions"

just --completions zsh > "$ZSH_SITE_FUNCTIONS/_just"
