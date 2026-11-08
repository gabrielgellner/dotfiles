# tab_bar.py - kitty's tab bar drawn as dot_tmux.conf's status line.
#
# Loaded by `tab_bar_style custom` in mux.conf. The same layout and Frappé
# colours as tmux's bar, read off dot_tmux.conf:
#
#     " <session> " [1 nvim] [2 console] [3 console]    ♪ … ⣿ 0 (0) ⣤ 0 ⣀ 1 Sun 08 Nov 21:48
#
# The right side is the same two scripts tmux runs from status-right, unchanged
# apart from one flag. They print tmux's #[fg=…] markup, which is translated
# here rather than taught a second output format, so the bar and tmux's stay
# one source.
#
# kitty draws the tab bar on its main thread, the one that also handles typing,
# so the scripts must never run inside draw_tab: claude-tmux-status forks ps,
# and a slow gmuse socket would freeze the terminal. A repeating timer starts
# them on a worker thread every 5s (tmux's status-interval) and redraws when
# what they printed, or the minute, has changed.
#
# Not ported: tmux's activity and bell styles. Both were set in dot_tmux.conf,
# but every part of the window format sets its own fg and bg, which overrides
# them, so neither ever showed.

import os
import re
import subprocess
import threading
import time

from kitty.boss import Boss
from kitty.child import default_env
from kitty.fast_data_types import Screen, add_timer, get_boss, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

BAR_BG = 0x292C3C
TEXT = 0xC6D0F5
INDEX_FG = 0x232634
INDEX_BG = 0x949CBB
INDEX_BG_ACTIVE = 0xCA9EE6
TITLE_BG = 0x414559
TITLE_BG_ACTIVE = 0x51576D
DATE = 0x737994
CLOCK = 0x949CBB

# tmux's status-left-length.
SESSION_MAX = 30
# A tick a second to notice changes, and the scripts on every fifth: tmux's
# status-interval 5.
INTERVAL = 1.0
RUN_EVERY = 5

STATUS_SCRIPTS = (
    ("gmuse", [os.path.expanduser("~/bin/gmuse-tmux-status")]),
    ("claude", [os.path.expanduser("~/bin/claude-tmux-status"), "--panes-stdin"]),
)

_status = {"gmuse": "", "claude": ""}
_worker = None
_timer = None
_ticks = 0
_drawn: tuple[str, str, str] | None = None

# kitty's own process has launchd's bare PATH. default_env() is what kitty
# gives its windows, read from the login shell, so the scripts find gmuse in
# ~/.local/bin as they do from tmux.
_env = None


def _run_scripts(panes: str) -> None:
    global _env
    if _env is None:
        _env = {**os.environ, **default_env()}
    for key, cmd in STATUS_SCRIPTS:
        try:
            res = subprocess.run(
                cmd,
                input=panes if key == "claude" else "",
                capture_output=True,
                text=True,
                timeout=3,
                env=_env,
            )
            _status[key] = res.stdout
        except Exception:
            _status[key] = ""


def _panes(boss: Boss) -> str:
    # What claude-tmux-status gets from `tmux list-panes` under tmux: each
    # window's shell pid and the session it belongs to, which the script walks
    # up to from every running claude. Read here because only the main
    # thread may touch the boss.
    lines = []
    for w in boss.all_windows:
        name = w.created_in_session_name
        pid = w.child.pid
        if name and pid:
            lines.append(f"{pid} {name}")
    return "\n".join(lines) + "\n"


def _tick(timer_id: int | None) -> None:
    global _worker, _ticks, _drawn
    boss = get_boss()
    if _ticks % RUN_EVERY == 0 and (_worker is None or not _worker.is_alive()):
        _worker = threading.Thread(target=_run_scripts, args=(_panes(boss),), daemon=True)
        _worker.start()
    _ticks += 1
    # The worker finishes after the tick that started it, so redrawing only on
    # the 5s beat drew each result one beat late — measured up to ~9s behind a
    # state change, and the clock with it. Checking every second and redrawing
    # on any change keeps it within a second of the scripts, which run on
    # tmux's 5s.
    shown = (_status["gmuse"], _status["claude"], time.strftime("%H:%M"))
    if shown == _drawn:
        return
    _drawn = shown
    # update_tab_bar_data redraws now; mark_tab_bar_dirty alone only flags it
    # for kitty's render loop, which left a test kitty behind other windows
    # showing a stale count.
    for tm in boss.all_tab_managers:
        tm.update_tab_bar_data()
        tm.mark_tab_bar_dirty()


_MARKUP = re.compile(r"#\[([^\]]*)\]")


def _parse(markup: str) -> list[tuple[int | None, bool, str]]:
    """tmux's #[fg=#rrggbb], #[bold] and #[default] as (fg, bold, text) runs.

    Only what the two scripts emit; fg None is the bar's own text colour.
    """
    runs = []
    fg, bold, pos = None, False, 0
    for m in _MARKUP.finditer(markup):
        if m.start() > pos:
            runs.append((fg, bold, markup[pos : m.start()]))
        for attr in m.group(1).split(","):
            attr = attr.strip()
            if attr == "default":
                fg, bold = None, False
            elif attr.startswith("fg=#"):
                fg = int(attr[4:], 16)
            elif attr == "bold":
                bold = True
            elif attr == "nobold":
                bold = False
        pos = m.end()
    if pos < len(markup):
        runs.append((fg, bold, markup[pos:]))
    return [(f, b, t.replace("##", "#")) for f, b, t in runs if t]


def _draw(screen: Screen, text: str, fg: int, bg: int, bold: bool = False) -> None:
    screen.cursor.fg = as_rgb(fg)
    screen.cursor.bg = as_rgb(bg)
    screen.cursor.bold = bold
    # kitty arrives with active_tab_font_style (bold-italic) already applied to
    # the cursor for the active tab; tmux drew it upright.
    screen.cursor.italic = False
    screen.draw(text)


def _width(runs: list[tuple[int | None, bool, str]]) -> int:
    return sum(wcswidth(t) for _, _, t in runs)


def _draw_right(screen: Screen, start: int) -> None:
    clock = [(DATE, False, time.strftime("%a %d %b ")), (CLOCK, False, time.strftime("%H:%M "))]
    claude = _parse(_status["claude"])
    gmuse = _parse(_status["gmuse"])
    # When it does not all fit, gmuse goes first, then Claude: the same order
    # of importance as their placement, leftmost being least urgent.
    room = screen.columns - start - 1
    for runs in (gmuse + claude + clock, claude + clock, clock):
        if _width(runs) <= room:
            break
    else:
        return
    screen.cursor.x = screen.columns - _width(runs)
    for fg, bold, text in runs:
        _draw(screen, text, TEXT if fg is None else fg, BAR_BG, bold)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global _timer
    if _timer is None:
        _timer = add_timer(_tick, INTERVAL, True)
        _tick(None)

    # status-left " #S ", in the bar's own colours. active_session_name goes
    # empty while the dev picker is open, because its overlay belongs to no
    # session; the first tab shown is the current session's (tab_bar_filter),
    # so its own session_name is the same answer and survives the overlay.
    name = tab.active_session_name or tab.session_name
    if index == 1 and name:
        if len(name) > SESSION_MAX:
            name = name[: SESSION_MAX - 1] + "…"
        _draw(screen, f" {name} ", TEXT, BAR_BG)

    # window-status-format and its -current- twin:
    # "#[fg=#232634,bg=#949cbb] #I #[fg=#c6d0f5,bg=#414559] #W "
    title = tab.title
    budget = max(max_tab_length - len(str(index)) - 4, 1)
    if wcswidth(title) > budget:
        title = title[: budget - 1] + "…"
    _draw(screen, f" {index} ", INDEX_FG, INDEX_BG_ACTIVE if tab.is_active else INDEX_BG)
    _draw(screen, f" {title} ", TEXT, TITLE_BG_ACTIVE if tab.is_active else TITLE_BG)
    end = screen.cursor.x

    if is_last:
        _draw_right(screen, end)
    else:
        # window-status-separator " ".
        _draw(screen, " ", TEXT, BAR_BG)
    return end
