# Shell history — atuin

Atuin records every command into SQLite with its **directory**, **exit code** and
**duration**. That is the whole point: a flat `.zsh_history` has nowhere to put
those, so questions like "the version that worked" were unanswerable before.

Installed by `bootstrap.sh`, wired in `dot_zshrc` after fzf and
zsh-autosuggestions. Local only — no account, nothing leaves the machine.

## Keys

| Key           | Mode   | Does                                    |
| ------------- | ------ | --------------------------------------- |
| `Ctrl-R`      | insert | atuin search UI (was fzf)                |
| `Up`          | insert | atuin, filtered by what you have typed   |
| `Ctrl-P/N`    | insert | step back/forward, prefix match — unchanged |
| `Ctrl-Y`      | insert | accept the ghost suggestion — unchanged  |
| `Ctrl-T`      | insert | fzf file picker — still fzf, untouched   |
| `k` `/`       | normal | still vi motions, deliberately restored  |

Inside the search UI, atuin prints its own hint line — `<esc>: exit,
<tab>: edit, <enter>: run, <ctrl-o>: inspect`. Two more are not in it:

| Key       | Does                                                    |
| --------- | ------------------------------------------------------- |
| `Ctrl-R`  | cycle filter — GLOBAL, HOST, SESSION, DIRECTORY          |
| `Ctrl-S`  | cycle search mode — shows `[ SRCH: PREFIX ]` etc.        |
| `Enter`   | run it immediately (`enter_accept = true`)               |
| `Tab`     | put it on the command line without running               |
| `Ctrl-O`  | inspect: directory, exit code, duration                  |
| `Esc`     | cancel, restoring what you had typed                     |

`Ctrl-R` cycling the filter is the one worth learning: press it three more times
after opening and the indicator reads `[ DIRECTORY ]`, scoping every subsequent
keystroke to this repo.

## Queries

The interface is filter flags, not grep. They compose.

    atuin search --cwd .                     # what do I run in this repo
    atuin search --exit 0 cargo              # the cargo command that worked
    atuin search --exclude-exit 0 --cwd .    # everything that failed here
    atuin search --after "yesterday 3pm"     # since yesterday afternoon
    atuin search --before 2026-08-01 --cwd . # before August

`--after`/`--before` take plain language: `yesterday 3pm`, `last friday`,
`2026-08-01`, `3 days ago`.

### Output shape

    atuin search --cwd . --format "{time} {exit} {command}"

Placeholders: `{command}` `{directory}` `{duration}` `{exit}` `{time}`
`{relativetime}` `{user}` `{host}`. Also `--limit`, `--offset`, `--reverse`,
`--human`.

### Stats

    atuin stats              # all history
    atuin stats week
    atuin stats last friday

## The workflow this is actually for

**Promotion.** Decide what deserves a `just` recipe from evidence rather than
guesswork. In a project:

    atuin search --cwd . --include-duplicates --format "{command}" \
      --limit 5000 | sort | uniq -c | sort -rn | head -20

`--include-duplicates` is not optional here. Without it a non-interactive
search returns each distinct command once, so every count comes back as 1 and
the ranking is silently meaningless.

Recipes show up as `just check`, so anything near the top that is *not* a `just`
invocation is a command being typed raw — a promotion candidate. Seeing
`just check` dominate means the interface is earning its keep.

Run it in reverse against `just --summary` to find recipes never invoked at all.

**Cold re-entry.** Coming back to a project after months:

    atuin search --cwd ~/dev/cmft --after "6 months ago" --format "{time} {command}"

`just --list` gives the interface; this gives the practice, including setup steps
that never became recipes.

**Failure forensics.** `atuin search --exclude-exit 0 --cwd .` — what has been
fighting you here.

**Cross-project transfer.** `atuin search --cwd ~/dev/pinax pytest` — how the
sibling repo does it.

## Ghost text

zsh-autosuggestions now reads atuin first, zsh history as fallback
(`ZSH_AUTOSUGGEST_STRATEGY=(atuin history)`). Same key, same look; the pool is
larger because `HIST_IGNORE_ALL_DUPS` no longer deletes repeats out of it. Still
prefix-matched, so the feel is unchanged.

## Things worth knowing

Imported history has **no directory or exit code** — `unknown` and `-1`. The old
file never recorded them. Only commands run since the switch carry context, so
`--cwd` and `--exit` get more useful over the first few weeks.

Non-interactive `atuin search` collapses duplicates unless you pass
`--include-duplicates`. Fine for "what did I run", wrong for "how often" — and
it fails quietly, as a list of 1s.

`atuin import auto` is **not idempotent**. Running it twice duplicates
everything. `bootstrap.sh` guards on the database already existing.

Atuin binds vi normal-mode `k` and `/` to its search by default. `dot_zshrc`
puts both back, since that is broken vi rather than a different history tool.
Delete those two lines to try the stock bindings.

`?` would be bound to Atuin AI; `--disable-ai` turns that off, so `?` still types
a question mark.

## See also

- [Command line](cmdline.md) — the zsh/vim command line itself
- [Navigation](navigation.md)
