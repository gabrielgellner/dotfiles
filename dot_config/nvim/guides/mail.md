# Mail (neomutt)

`neomutt` in any terminal. It reads a **local copy** of Proton Mail, so it is
fast, sorts properly and works offline; a background job keeps that copy in
step with Proton every two minutes, whether neomutt is open or not.

```
Proton ⇄ Proton Mail Bridge ⇄ mbsync (every 2m) ⇄ ~/.local/share/mail/proton ⇄ neomutt
                            ⇄ himalaya (Claude, straight to Bridge)
```

**Bridge has to be running** — the menu-bar app, started at login. Without it
neomutt still opens and shows everything synced so far; nothing new arrives and
nothing reaches Proton until it is back.

`?` in any screen lists every key it has. The config is
`~/.config/neomutt/neomuttrc`; the why behind each choice is in the dotfiles'
`CLAUDE.md`, under Mail.

## The two screens

The **index** is the message list you start in; `Enter` opens a message in the
**pager**. `q` in the pager goes back to the index; `q` in the index **asks**
"Quit NeoMutt?", and the default is no — `Enter` stays, `y` quits. `x` (quit
without applying deletes) asks the same way.

## Moving in the index

| Key                 | Does                                                        |
| ------------------- | ----------------------------------------------------------- |
| `j` / `k`           | next / previous message                                     |
| `gg` / `G`          | first / last                                                |
| `Ctrl-d` / `Ctrl-u` | half a page down / up                                       |
| a number, `Enter`   | jump to that row — every row is numbered on the left        |
| `Tab`               | next unread message                                         |
| `J` / `K`           | next / previous **folder** in the sidebar (`Ctrl-j` / `Ctrl-k`) |
| `c`                 | go to a folder by name: `c +Arc<Tab>`, `c +Labels/Rec<Tab>` |

## Threads

Folders open with **every thread collapsed** to one row, which shows how many
messages it holds — `(3) AGM videos`. A collapsed thread with anything unread
in it is **bold blue**.

| Key     | Does                                        |
| ------- | ------------------------------------------- |
| `Enter` | read the thread, from its first message     |
| `Esc v` | open / collapse the thread under the cursor |
| `Esc V` | open / collapse every thread                |

**Reading a thread keeps you inside it.** `Enter` narrows the index to that
thread and opens it; `J` / `K` walk it and stop at either end, as do `d` and
`a` on its last message. `q` brings the whole folder back, every thread
collapsed again, the cursor on the one you read. Coming back clears a limit set
with `l`, too. The line under the message says where you are:
`thread 2/4 · 37/880` is the second of four in the thread, 37th in the folder.

## In the pager

| Key           | Does                                                          |
| ------------- | ------------------------------------------------------------- |
| `j` / `k`     | scroll a line                                                 |
| `Space` / `-` | next / previous page                                          |
| `J` / `K`     | next / previous message **in the thread** — `Ctrl-j`/`k`, `Ctrl-n`/`p` too |
| `q` or `i`    | back to the folder, threads collapsed                         |
| `v`           | attachments                                                   |
| `gx`          | list the message's links; `j`/`k`, `Enter` opens one          |

`J` / `K` mean folders in the index and messages in the pager — the same keys,
one level apart, by the capital-is-wider rule in [Keymaps](keymaps.md). `Ctrl-j` /
`Ctrl-k` are the same moves, as nvim's step to the window below / above.

**Links.** `gx` (in the index too) lists every link in the message — HTML
ones included, whole even when they wrap — each in the sentence it came from.
`j`/`k` to move, `Enter` opens it in the browser and closes the list, `q`
leaves. Without it, kitty's `Ctrl+Shift+E` labels the links on screen, and
`Shift`-click opens one past tmux.

**Attachments.** `v` lists them; then:

| Key     | Does                                                          |
| ------- | ------------------------------------------------------------- |
| `Enter` | an image: shown inline in kitty — `Enter` again to come back   |
| `Enter` | a PDF: opens in Preview                                       |
| `o`     | any attachment: opens in its macOS app                        |
| `s`     | save it somewhere                                             |

Inline images need kitty; through tmux they need passthrough, which the
viewer switches on for its own pane.

## Folders and labels

Proton puts every message in **one folder** — Inbox, Archive, Sent, Trash — and
lets it carry **any number of labels**. Archive is the home for everything
filed: the counterpart of Gmail's "All Mail minus the Inbox". The Inbox is for
what still needs something from you.

Labels show in the sidebar as folders under `Labels/`, and opening one lists
every message with that label. A message with three labels is three files on
disk, but it is still one message on Proton — the sync keeps them consistent.

**Labels have their own two keys, `+` and `-`**, and both work from any
folder. (`t` is not labelling — it only *selects*; see Tagging below.)

| To                                | Keys                                         |
| --------------------------------- | -------------------------------------------- |
| add a label, keep it in the Inbox | `+`, `Rec<Tab>`, `Enter`                     |
| label it **and** clear the Inbox  | the same, then `a`                           |
| several at once                   | `t` each, then `;+` … `Enter`, then `;a`     |
| take a label off                  | `-`, then the number of the label            |

`+` opens the copy prompt with `+Labels/` already typed; `Tab` completes the
name. `-` lists the labels this message carries and removes the one you pick
(through `~/bin/mail-unlabel`); `Enter` alone removes nothing.

Never *move* (`s`) a message into a label folder. A move is a copy plus a
delete, and both halves were measured: the copy adds the label, and the delete
from Inbox or Archive leaves the message in no folder at all, findable only
in All Mail and its labels. Label, then archive.

New mail is labelled on arrival by a filter in Proton ("Auto-label by sender").
Receipts, Community and Cooking also skip the Inbox; everything else lands in
the Inbox, labelled, until you archive it.

## Acting on mail

| Key               | Does                                                   |
| ----------------- | ------------------------------------------------------ |
| `a`               | **archive** — move to Archive                          |
| `d`               | **delete** — move to Trash                             |
| `d` in `Labels/x` | **delete** too — the whole message goes to Trash        |
| `d` in Trash      | delete **for good** (Proton too, after the next sync)  |
| `u`               | undo a delete, before it is applied                    |
| `+` / `-`         | **add / remove a label** (see Folders and labels)       |
| `s`               | move to any folder (`a` is `s +Archive`)               |
| `F`               | star / unstar                                          |
| `N`               | mark read / unread                                     |
| `$`               | **apply** the pending moves and deletes now            |

**Deletes and moves are marked first, applied later.** A deleted message turns
red and stays until `$`, a change of folder, or quitting — then it happens
without a question. Until then `u` takes it back.

## Tagging several at once

**In mutt, "tag" means *select*, not label.** A tagged message is marked for
the next action and nothing more — it gets no label, on Proton or anywhere.
For labels, see "Labelling an email" above.

| Key            | Does                                              |
| -------------- | ------------------------------------------------- |
| `t`            | tag / untag the message under the cursor          |
| `T`            | tag everything matching a pattern: `T ~f porkbun` |
| `Esc t`        | tag the whole thread                              |
| `Ctrl-t`       | untag by pattern — `Ctrl-t ~A` untags everything  |
| `;` then a key | do it to every tagged message: `;a`, `;d`, `;+`   |

## Finding things

`l` (**limit**) shows only what matches, in the folder you are in, and `/`
searches it. Patterns combine, and `!` negates one:

| Pattern      | Matches                            |
| ------------ | ---------------------------------- |
| `~f amy`     | from Amy                           |
| `~s invoice` | subject contains "invoice"         |
| `~d <2w`     | newer than two weeks               |
| `~N` / `~U`  | new / unread                       |
| `~F`         | starred                            |
| `~A`         | everything — `l ~A` clears a limit |

`l ~f amy ~d <1m` is from Amy, in the last month; `l !~f amazon` is everything
else.

**`\` searches every folder at once** — Inbox, Archive, Sent and every label,
bodies included, **and the Gmail archive** (2009 onwards) — through notmuch,
and the results come back as whole threads, your own replies from Sent among
them. `tag:gmail` narrows to the archive, and its old Gmail labels are tags:
`tag:gmail tag:"Product Serial"`.

| Query                                     | Finds                   |
| ----------------------------------------- | ----------------------- |
| `from:amy subject:passport`               | both, anywhere          |
| `porkbun date:2026-05..2026-06`           | a word, in a date range |
| `attachment:pdf from:cra-arc.gc.ca`       | PDFs from the CRA       |
| `folder:"Labels/Receipts" not tag:unread` | a label, read only      |

The sidebar's **Last 2 weeks** and **Starred** are saved searches of the same
kind, named `recent` and `starred` in notmuch's config (`query:starred`). A
result behaves like a message in a folder — `d` there moves it to Trash too.

> **Never give a message the notmuch tag `deleted`.** It becomes the mail
> file's "trashed" flag, and the sync turns that into a **permanent delete** on
> Proton. Delete with `d`, as everywhere else.

## Writing

| Key  | Does                     |
| ---- | ------------------------ |
| `m`  | new message              |
| `r`  | reply to the sender      |
| `gr` | reply to everyone        |
| `f`  | forward                  |
| `R`  | reopen a postponed draft |

**Addresses complete with `Ctrl-Y`** (or `Ctrl-T`) at the To:, Cc: and Bcc:
prompts: type part of a name or address, then `Ctrl-Y`. One match fills in; more
open a list that takes nvim's completion keys — `Ctrl-N`/`Ctrl-P` to move,
`Ctrl-Y` to take one (`Enter` too), `Ctrl-E` to leave. It draws on
all your mail, Proton and the Gmail archive, people you have written to first;
the list is rebuilt daily (`mail-contacts --rebuild` to force it). `Tab` there
completes only aliases.

nvim opens with the headers at the top — edit To, Cc and Subject right there.
After `:wq` comes the compose screen: `y` sends, `a` attaches, `q` gives up
(it asks). Bridge files the sent copy in Sent itself; nothing here saves a
second one.

`gr` and not mutt's `g`: binding `gg` made `g` a prefix, which took reply-all
with it.

## Emptying Trash

Either place works, **as long as the sync is not in the middle of your
deletes**. Press `$`, give it a sync (two minutes), then empty:

- **in Proton** — Trash → *Empty trash*; or
- **in neomutt** — `c +Trash`, `D`, `~A`, `$`.

For up to a minute afterwards Proton's All Mail can still show a deleted
message. It goes.

## When something looks wrong

| To                   | Run                                                    |
| -------------------- | ------------------------------------------------------ |
| sync now             | `launchctl kickstart gui/$(id -u)/local.mbsync-proton` |
| see sync errors      | `tail ~/Library/Logs/mbsync-proton.log`                |
| check it ran cleanly | `launchctl print gui/$(id -u)/local.mbsync-proton`     |

Mostly "connection refused" in that log, which means Bridge is not running. A
run of "far side refuses to store message" means a delete crossed an empty of
Trash; the recovery is written up in the dotfiles' `CLAUDE.md`. Do not run
`mbsync` by hand while the agent is loaded — two at once collide.

## Backup

The local copy is backed up to the NAS every night at 03:30 — encrypted on the
laptop with restic before it leaves, so `asnas` only ever holds ciphertext. A
run missed while the laptop sleeps happens when it wakes; one missed away from
home fails and the next night's catches up.

The repository is `sftp:asnas:/volume1/Backups/mail-restic`, and `-r …` in the
table stands for `-r` followed by that address.

| To                    | Run                                         |
| --------------------- | ------------------------------------------- |
| back up now           | `mail-backup`                               |
| see how the last went | `tail ~/Library/Logs/mail-backup.log`       |
| list snapshots        | `restic -r … snapshots`                     |
| restore into a folder | `restic -r … restore latest --target ~/out` |

restic asks for the password unless `RESTIC_PASSWORD_COMMAND` is set to
`security find-generic-password -s restic-mail -w`, which is what the script
does.

The password is in the keychain as `restic-mail` **and in Bitwarden** — without
it the backup cannot be opened, by anyone.

## Saving attachments

`mail-attachments` copies what is worth keeping out of the mail onto the NAS —
photos to `Media/Photos/From email/<year>/`, ebooks to `Media/Books/`, and
documents, images, audio and other files under `records/`. Run it whenever;
it only ever adds what is not there yet.

| To                          | Run                                       |
| --------------------------- | ----------------------------------------- |
| see what it would save      | `mail-attachments`                        |
| save it                     | `mail-attachments --write`                |
| only mail since a date      | `mail-attachments --since 2026-11-01`     |
| only photos                 | `mail-attachments --only photo`           |
| the Gmail archive instead   | `--mail ~/.local/share/mail/gmail-archive` |
| after moving files on NAS   | `mail-attachments --rescan`               |

Both NAS shares need to be mounted in Finder first. Saving does not remove
anything from the mail — Proton cannot strip an attachment from a message.

See also [tmux.md](tmux.md) for getting around the sessions neomutt runs in.
