# music_popup.py - toggle gmuse in kitty's floating quick-access window, sized
# like the tmux popup it replaces: 90% x 85% of the kitty window it opens over.
#
# Bound to ctrl+a>ctrl+p in mux.conf, as `kitten music_popup.py`. A kitten with
# no_ui runs inside kitty's own process, which is the point: it can read the
# active window's size directly. The two shell versions tried first could not.
# A background `launch` gets no KITTY_LISTEN_ON, so `kitten @ ls` falls back to
# /dev/tty and fails, and --copy-env leaves that variable out too (both
# measured). A fixed size cannot do the job either: the laptop's own display
# is 1280x832 points, and the 147x38 cells that suit a 163x43 window on an
# external screen came out 1323x798, wider than it.
#
# The size only matters on the press that starts the popup. While it is
# running, quick-access-terminal ignores its arguments and toggles visibility,
# so a press from inside the popup (its own kitty, reading the same mux.conf)
# simply hides it.
#
# hide_on_focus_loss makes clicking back into kitty dismiss it, as a modal
# popup would. tab_bar_style is overridden because mux.conf's tab bar would
# otherwise draw a status line inside the player.

import subprocess

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.child import default_env
from kitty.constants import kitten_exe


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    cmd = [
        kitten_exe(),
        "quick-access-terminal",
        "-o", "edge=center-sized",
        "-o", "background_opacity=1",
        "-o", "hide_on_focus_loss=yes",
        "-o", "kitty_override=tab_bar_style=hidden",
    ]
    w = boss.window_id_map.get(target_window_id) or boss.active_window
    if w is not None:
        cmd += [
            "-o", f"columns={w.screen.columns * 90 // 100}",
            "-o", f"lines={w.screen.lines * 85 // 100}",
        ]
    cmd.append("gmuse")
    # Not waited on: the first press starts the popup's own process, which runs
    # until gmuse quits. default_env() is the login-shell environment kitty
    # gives its windows; kitty's own is launchd's bare PATH, with no gmuse.
    subprocess.Popen(cmd, env=default_env(), start_new_session=True,
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
