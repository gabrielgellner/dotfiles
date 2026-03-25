# dotfiles justfile

# list available recipes
default:
    @just --list

# ── chezmoi ───────────────────────────────────────────────────────────────────

# preview pending changes
diff:
    chezmoi diff

# apply dotfiles to home directory
apply:
    chezmoi apply -v

# pull upstream changes and apply
update:
    chezmoi update -v

# ── changelog ─────────────────────────────────────────────────────────────────

# regenerate full CHANGELOG from git history
changelog:
    git-cliff --output CHANGELOG.md

# preview changelog for unreleased commits (no file write)
changelog-preview:
    git-cliff --unreleased

# ── release ───────────────────────────────────────────────────────────────────

# show what version git-cliff would bump to next
next-version:
    #!/usr/bin/env bash
    ver=$(git-cliff --bumped-version)
    [[ "$ver" == v* ]] || ver="v$ver"
    echo "$ver"

# tag a release — version auto-determined from commits, or pass one explicitly: just release v1.2.3
release version="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "{{ version }}" ]]; then
        ver=$(git-cliff --bumped-version)
        # ensure v prefix (git-cliff omits it when there are no prior tags)
        [[ "$ver" == v* ]] || ver="v$ver"
    else
        ver="{{ version }}"
    fi
    echo "Releasing $ver..."
    git-cliff --tag "$ver" --output CHANGELOG.md
    git add CHANGELOG.md
    git commit -m "chore(release): $ver"
    git tag -a "$ver" -m "Release $ver"
    git push && git push --tags
    echo "Done — $ver tagged and pushed."
