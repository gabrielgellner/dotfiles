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

# Eleven commits have subjects git-cliff cannot file under a real group, and all
# of them are permanent: main rejects force-push, so the subjects cannot be
# reworded. They fail in two different ways, which is worth keeping straight —
# an earlier version of this note ran them together.
#
# Eight are dropped outright. filter_unconventional = true discards a subject
# that is not conventional-commit shaped. These are chezmoi's own
# "Update <path> Add <path>" messages from the window when autoCommit was
# enabled — see the comment in .chezmoi.toml.tmpl for why it is off now. They
# leave 2026-07-10 to 2026-08-22 with no changelog entries, including
# scratch.lua, rules_lookup.lua and markdown_outline.lua being added. Left that
# way deliberately rather than papered over with a catch-all parser.
#
# git-cliff names them itself — its warning ends "(run with `-vv` for details)",
# and -vv prints the reason per commit:
#
#     git-cliff -vv --output /dev/null 2>&1 | grep 'did not match conventional'
#
# An earlier version of this note said git-cliff reported only a count and never
# which ones, and gave this as the way to find them, which still works:
#
#     git log --format='%h %s' | grep -E '^\S+ (Update|Add) '
#
# Three more are not dropped at all: "nvim:", "chezmoi:" and "nvim/zk:" parse
# fine as conventional commits, they just name types that do not exist, so each
# used to raise its own heading ("### Nvim/zk") beside the real ones. cliff.toml
# maps those three prefixes onto the groups they belong in. Any type with no
# parser still renders under its own name, which is deliberate — a typo like
# "fux:" announces itself instead of vanishing.
#
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
    # set -e like `release` below: without it a git-cliff failure left $ver empty
    # and this printed a bare "v".
    set -euo pipefail
    ver=$(git-cliff --bumped-version)
    [[ "$ver" == v* ]] || ver="v$ver"
    echo "$ver"

# tag a release — version auto-determined from commits, or pass one explicitly: just release v1.2.3
release version="":
    #!/usr/bin/env bash
    set -euo pipefail
    # Guards before anything is written. main is protected and rejects
    # force-push, so a bad release commit cannot be reworded away afterwards.
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "working tree is dirty — commit or stash first" >&2
        echo "  (git add CHANGELOG.md below would otherwise sweep in whatever is staged)" >&2
        exit 1
    fi
    if [[ -z "{{ version }}" ]]; then
        ver=$(git-cliff --bumped-version)
        # ensure v prefix (git-cliff omits it when there are no prior tags)
        [[ "$ver" == v* ]] || ver="v$ver"
    else
        ver="{{ version }}"
    fi
    # Before committing, not after: `git tag` failing on an existing tag used to
    # abort here leaving a chore(release) commit with nothing tagging it.
    if git rev-parse -q --verify "refs/tags/$ver" >/dev/null; then
        echo "tag $ver already exists" >&2
        exit 1
    fi

    echo "Releasing $ver..."
    git-cliff --tag "$ver" --output CHANGELOG.md
    git add CHANGELOG.md
    git commit -m "chore(release): $ver"
    git tag -a "$ver" -m "Release $ver"
    # --follow-tags sends the commit and its annotated tag in one exchange.
    # `git push && git push --tags` could push the commit and then fail, leaving
    # the tag behind on this machine only.
    git push --follow-tags
    echo "Done — $ver tagged and pushed."
