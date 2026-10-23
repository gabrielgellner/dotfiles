# GitHub (octo)

Issues, pull requests and notifications as ordinary nvim buffers, through
octo.nvim. It is a front end to `gh`: every request is a `gh api` call, so if
`gh auth status` answers, octo works — there is no login of its own.

Where it sits beside the [Git](git.md) card:

| Tool       | Answers                                                  |
| ---------- | -------------------------------------------------------- |
| codediff   | "what does my branch change" — local, before anyone sees it |
| octo       | "what is happening on GitHub" — issues, PRs, review threads |

So `<leader>gm` is for reading your own branch; `<leader>or` is for a review
whose comments land on the pull request.

## Getting in

Everything global is under `<leader>o`. Lowercase is **this repo**, a capital
is **all of GitHub** — the same widening rule as `ff`/`fF`.

| Key          | Does                                                  |
| ------------ | ----------------------------------------------------- |
| `<leader>oi` | open issues in this repo                              |
| `<leader>oI` | open issues **involving you**, anywhere on GitHub     |
| `<leader>op` | open pull requests in this repo                       |
| `<leader>oP` | open pull requests involving you, anywhere            |
| `<leader>on` | notifications, all repos                              |
| `<leader>oc` | create an issue here                                  |
| `<leader>or` | start or resume a review of **this branch's** PR      |
| `<leader>ob` | this repo in the browser                              |
| `<leader>oo` | every Octo action, as a picker                        |

"Involving you" is GitHub's `involves:@me` — author, assignee, mentioned or
commented. "This repo" is the cwd's `upstream` remote, else `origin`.

An empty inbox is not an error: `<leader>on` says "There are no
notifications" and opens nothing.

The commands are worth knowing for what no key covers:

```
:Octo 42                       issue or PR 42 in this repo
:Octo <github url>             any issue, PR or discussion, by its URL
:Octo pr                       the PR for the checked-out branch
:Octo search <query>           GitHub search syntax, e.g. label:bug is:open
:Octo issue list owner/repo    another repo's issues, without cd'ing there
:Octo run list                 Actions runs
```

## In the pickers

The lists are snacks pickers — the frame on [Pickers](pickers.md) applies, and
`<CR>` opens the item as a buffer. On top of that:

| Key     | Does                                            |
| ------- | ----------------------------------------------- |
| `<C-b>` | open in the browser                             |
| `<C-y>` | copy the URL                                    |
| `<C-e>` | copy the head SHA (PRs)                         |
| `<C-o>` | **check the PR out** — `gh pr checkout`, in the cwd |

> **`<C-o>` acts on the cwd's repo.** It runs `gh pr checkout` where nvim
> is, so a PR list for another repo is not a safe place to press it.

> **There is no merge key in the picker, on purpose.** Upstream puts it on
> `<C-r>`, in insert mode as well, and merges the highlighted PR with no
> confirmation. A snacks prompt also starts `<C-r><C-w>` and `<C-r>%` with
> that key, so a slow second keystroke would merge. It is unbound
> (`plugins/octo.lua`); merge from the PR buffer with `\pm`, with the PR on
> screen.

## Reading an issue or PR

The buffer *is* the issue: title, a details block, the body, then the
timeline. `<localleader>` is `\`, and every key below is buffer-local — pause
on `\` and which-key lists them.

| Key           | Does                                      |
| ------------- | ----------------------------------------- |
| `]c` / `[c`   | next / previous comment                   |
| `<CR>`        | menu of everything you can do here        |
| `<C-r>`       | reload from GitHub                        |
| `<C-b>`       | open in the browser                       |
| `<C-y>`       | copy the URL                              |
| `\gi`         | jump to an issue `#number` under the cursor |
| `\il`         | the repo's open issues                    |

`]c` keeps the meaning it has everywhere else here — "next change" in a diff,
"next comment" in a conversation. `<C-b>` and `<C-y>` lose their scroll
meanings in these buffers only.

## Writing back

The buffer is editable, and `:w` sends it. Change the title, the body or one of
your own comments, then write. A buffer with unsent edits shows a mark in the
status column.

| Key              | Does                       |
| ---------------- | -------------------------- |
| `\ca`            | add a comment              |
| `\cr`            | reply to the comment       |
| `\cd`            | delete the comment         |
| `\ce`            | a comment's edit history   |
| `\la` / `\ld`    | add / remove a label       |
| `\aa` / `\ad`    | add / remove an assignee   |
| `\ic` / `\io`    | close / reopen             |
| `\r+` `\r-` `\rh` `\re` `\rr` `\rl` `\rp` `\rc` | react 👍 👎 ❤️ 👀 🚀 😄 🎉 😕 |

`\ca` opens an empty comment block; type into it and `:w`.

> These were read from octo's config, not exercised: every one of them
> writes to GitHub. The reading half of this card was driven; this half was
> not.

## Pull requests

A PR buffer has everything above, plus the `\p` and `\v` families:

| Key              | Does                                            |
| ---------------- | ----------------------------------------------- |
| `\po`            | check the PR out locally                        |
| `\pd`            | the whole diff, in a buffer                     |
| `\pf`            | changed files, as a picker                      |
| `\pc`            | commits, as a picker                            |
| `\pa`            | **approve**                                     |
| `\pm`            | merge (merge commit)                            |
| `\psm` / `\prm`  | squash and merge / rebase and merge             |
| `\va` / `\vd`    | request / un-request a reviewer                 |
| `\ve`            | start or resume a review — same as `<leader>or` |
| `\tc`            | fold or unfold the CI checks list               |
| `\gc`            | open the CI check under the cursor              |
| `]s` / `[s`      | up / down a stack of PRs                        |

> **`\pa` is not upstream's key.** Octo binds approve to `<leader>qa`,
> buffer-locally — the only octo key outside `\`, and it lands in this config's
> quit group, a typo from `<leader>qq`. It is moved beside the other PR verbs.

For reading a PR's code rather than its conversation, checking it out with
`\po` and then `<leader>gm` gives you codediff with LSP, gitsigns and
everything else working. The review below is for when the comments need to
reach GitHub.

## Reviewing

`<leader>or` (or `\ve` in a PR buffer) opens the review in **a new tab** — a
file panel and a two-sided diff. `g<Tab>` flips back to where you were, as on
the [Git](git.md) card. Comments you make are *pending* until you submit, just
as on the website.

| Key            | Does                                                 |
| -------------- | ---------------------------------------------------- |
| `]q` / `[q`    | next / previous changed file                         |
| `[Q` / `]Q`    | first / last file                                    |
| `]u` / `[u`    | next / previous file you have not marked viewed      |
| `\<Space>`     | mark this file viewed                                |
| `]t` / `[t`    | next / previous comment thread                       |
| `\ca`          | comment on this line — in visual, on the range       |
| `\sa`          | a suggestion — in visual, replacing the range        |
| `\rt` / `\rT`  | resolve / unresolve the thread                       |
| `\e` / `\b`    | focus / toggle the file panel                        |
| `\C`           | review commit by commit                              |
| `\vs`          | **submit** — opens the summary window                |
| `\vd`          | discard the pending review                           |
| `<C-c>`        | close the review tab                                 |

The summary window from `\vs` is where the verdict is chosen. Type the summary,
then, in normal mode:

| Key     | Submits as      |
| ------- | --------------- |
| `<C-a>` | approve         |
| `<C-m>` | comment         |
| `<C-r>` | request changes |

> **`<C-m>` is Enter.** The terminal sends one byte for both, so `<CR>` in
> normal mode in the summary window submits the review as a comment. Finish
> the text, then press it on purpose.

> **Shadowed in a review.** `]t` is next todo and `]u` / `[u` walk undo states
> everywhere else; in a review tab octo's buffer-local keys win. Leave the tab
> for either.

## Recipes

**Triage your issues.** `<leader>oI`, type to filter, `<CR>` on one. Read it,
`\la` to label it, `<C-r>` if someone has just replied.

**Pick up someone's PR.** `<leader>op`, `<CR>` to read the conversation, `\po`
to check it out, `<leader>gm` to read the code with LSP. Back on the PR buffer,
`\ve` to leave comments where they will see them.

**Review a PR on GitHub's terms.** `<leader>or` on its branch. `]u` through the
unviewed files, `\<Space>` as each one is done, `V` and `\ca` on anything worth
a comment. `\vs`, write the summary, `<C-a>` or `<C-r>`.

**Open whatever someone pasted.** `:Octo ` then the URL.

## See also

- [Git](git.md) — codediff for reading a branch before there is a PR
- [Pickers](pickers.md) — the key frame every list here shares
- [Tmux](tmux.md) — `prefix + 1/2/3` for when the review tab is not enough

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
