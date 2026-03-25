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

# tag a new release: just release v1.2.3
release version:
    @echo "Releasing {{ version }}..."
    git-cliff --tag {{ version }} --output CHANGELOG.md
    git add CHANGELOG.md
    git commit -m "chore(release): {{ version }}"
    git tag -a {{ version }} -m "Release {{ version }}"
    git push && git push --tags
    @echo "Done — {{ version }} tagged and pushed."
