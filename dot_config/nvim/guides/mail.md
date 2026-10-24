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
| `J` / `K`           | next / previous **folder** in the sidebar                   |
| `c`                 | go to a folder by name: `c +Arc<Tab>`, `c +Labels/Rec<Tab>` |

## Threads

Folders open with **every thread collapsed** to one row, which shows how many
messages it holds — `(3) AGM videos`. A collapsed thread with anything unread
in it is **bold blue**.

| Key     | Does                                        |
| ------- | ------------------------------------------- |
| `Enter` | open the thread's first message             |
| `Esc v` | open / collapse the thread under the cursor |
| `Esc V` | open / collapse every thread                |

## In the pager

| Key           | Does                                                          |
| ------------- | ------------------------------------------------------------- |
| `j` / `k`     | scroll a line                                                 |
| `Space` / `-` | next / previous page                                          |
| `J` / `K`     | next / previous **message** — walks through a thread, then on |
| `q` or `i`    | back to the index                                             |
| `v`           | attachments                                                   |

`J` / `K` mean folders in the index and messages in the pager — the same keys,
one level apart.

## Folders and labels

Proton puts every message in **one folder** — Inbox, Archive, Sent, Trash — and
lets it carry **any number of labels**. Archive is the home for everything
filed: the counterpart of Gmail's "All Mail minus the Inbox". The Inbox is for
what still needs something from you.

Labels show in the sidebar as folders under `Labels/`, and opening one lists
every message with that label. A message with three labels is three files on
disk, but it is still one message on Proton — the sync keeps them consistent.

New mail is labelled on arrival by a filter in Proton ("Auto-label by sender").
Receipts, Community and Cooking also skip the Inbox; everything else lands in
the Inbox, labelled, until you archive it.

## Acting on mail

| Key               | Does                                                   |
| ----------------- | ------------------------------------------------------ |
| `a`               | **archive** — move to Archive                          |
| `d`               | **delete** — move to Trash                             |
| `d` in `Labels/x` | **take that label off**; the message stays where it is |
| `d` in Trash      | delete **for good** (Proton too, after the next sync)  |
| `u`               | undo a delete, before it is applied                    |
| `C`               | copy: `C +Labels/Receipts` **adds a label**            |
| `s`               | move to any folder (`a` is `s +Archive`)               |
| `F`               | star / unstar                                          |
| `N`               | mark read / unread                                     |
| `$`               | **apply** the pending moves and deletes now            |

**Deletes and moves are marked first, applied later.** A deleted message turns
red and stays until `$`, a change of folder, or quitting — then it happens
without a question. Until then `u` takes it back.

## Tagging several at once

| Key            | Does                                              |
| -------------- | ------------------------------------------------- |
| `t`            | tag / untag the message under the cursor          |
| `T`            | tag everything matching a pattern: `T ~f porkbun` |
| `Esc t`        | tag the whole thread                              |
| `Ctrl-t`       | untag by pattern — `Ctrl-t ~A` untags everything  |
| `;` then a key | do it to every tagged message: `;a`, `;d`, `;C`   |

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
bodies included — through notmuch, and the results come back as whole threads,
your own replies from Sent among them:

| Query                                     | Finds                   |
| ----------------------------------------- | ----------------------- |
| `from:amy subject:passport`               | both, anywhere          |
| `porkbun date:2026-05..2026-06`           | a word, in a date range |
| `attachment:pdf from:cra-arc.gc.ca`       | PDFs from the CRA       |
| `folder:"Labels/Receipts" not tag:unread` | a label, read only      |

The sidebar's **Last 2 weeks** and **Starred** are saved searches of the same
kind. A result behaves like a message in a folder — `d` there moves it to
Trash too.

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

See also [tmux.md](tmux.md) for getting around the sessions neomutt runs in.
