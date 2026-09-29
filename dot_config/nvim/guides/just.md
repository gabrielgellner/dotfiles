# Just recipes

Two repos here carry a `justfile`, and they answer different questions. The
dotfiles one is about getting config out of the repo and onto a machine; the
notes one is about getting notes off a machine and into the repo.

`just` with no arguments lists the recipes of whichever justfile is in scope,
and it searches **upward** from the working directory — `just --list` from
`~/notes/journal` finds the notes justfile. So "what can I run here" is always
one word, and you never need to be at the root.

## Notes — `~/notes`

| Recipe        | Does                                              |
| ------------- | ------------------------------------------------- |
| `just sync`   | commit anything new, pull, push, reindex          |
| `just status` | what is here, and what is not yet anywhere else   |
| `just hooks`  | arm the pre-push guard — **once per clone**       |

`sync` is the whole round trip and the only one you need day to day. In order:

1. **Commit**, if anything changed. The message is
   `chore: sync <date> <time>` with the changed paths in the body, which is the
   only thing that makes a wall of timestamped commits readable later.
2. **Pull**, with `--rebase`.
3. **Push**.
4. **Reindex**, so zk's pickers and link completion are right before nvim is
   even started.

**It commits before pulling**, and that order is deliberate: the alternative
needs a stash, and a stash that fails to pop mid-conflict is a worse place to be
than a commit that needs amending. Notes are worth keeping even half-written.

**It rebases rather than merges**, because two machines writing notes produce
genuinely independent commits and a merge bubble per sync would bury them.

### When it stops

A conflict — the same note changed on both machines — stops the rebase and
prints both ways out:

```
git add <file> && git rebase --continue && just sync
git rebase --abort
```

Nothing is auto-resolved. Merging two versions of a thought is not something a
script should guess at.

`sync` also warns, without failing, when the pre-push guard is inactive. A sync
that refuses to run is worse than an unguarded one, because the notes still need
to leave the machine. The fix is `just hooks`, and it is needed once per clone —
see [Notes](notes.md) for why that guard is a hook rather than a GitHub rule.

## Dotfiles — `~/.local/share/chezmoi`

| Recipe                   | Does                                        |
| ------------------------ | ------------------------------------------- |
| `just diff`              | preview pending changes                     |
| `just apply`             | apply to the home directory                 |
| `just update`            | pull upstream, then apply                   |
| `just changelog`         | regenerate CHANGELOG.md from history        |
| `just changelog-preview` | the unreleased section only, no file write  |
| `just next-version`      | what version the commits would bump to      |
| `just release [v1.2.3]`  | changelog, commit, tag, push                |

`diff` before `apply` is the habit worth having, and not only out of caution:
several tracked files have **two writers**, where the application rewrites the
file behind chezmoi's back. Claude Code's `settings.json`, karabiner's
`karabiner.json` and btop's `btop.conf` are all like this, and for those the
order is `chezmoi re-add <file>` *first*, or an apply silently reverts what you
changed in the app. CLAUDE.md lists which files and why.

### Releasing

`release` works out the version from the commits, or takes one explicitly. It
guards before it writes anything:

- **a dirty tree is refused** — otherwise `git add CHANGELOG.md` would sweep in
  whatever else was staged
- **an existing tag is refused**, and this check runs *before* the commit, since
  failing after it left a `chore(release)` commit with nothing tagging it

Then it writes the changelog, commits, tags, and pushes with `--follow-tags` so
the commit and its annotated tag go in one exchange — `git push && git push
--tags` can push the commit and then fail, leaving the tag on one machine only.

**A published release is final.** `main` and `v*` tags both carry GitHub
rulesets refusing deletion and non-fast-forward, so a release that ships
something wrong is fixed by cutting the next version, not by moving the tag.
Retagging means disabling the ruleset in Settings first, on purpose.

## See also

- [Notes](notes.md) — the three note tiers, and what `just sync` is syncing
- [Git](git.md) — reading and staging changes before any of this
