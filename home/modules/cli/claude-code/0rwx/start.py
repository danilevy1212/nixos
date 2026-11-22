"""SessionStart hook: a forked or resumed session keeps its 0rwx mode
(https://0rwx.com) instead of falling back to READ.

A fork has a new session_id, and SessionEnd removes a resumed session's mode
file, so neither has one. The transcript does hold every mode the
UserPromptSubmit hook (prompt.py) announced, as hook_additional_context
entries, and a fork's transcript is a copy of its origin's. The last entry is
the mode to restore.
https://code.claude.com/docs/en/hooks#sessionstart
The mode file lives under $XDG_STATE_HOME/claude-mode, named by session_id.
"""
import json
import os
import re
import sys
from pathlib import Path


def restore_mode(data: dict) -> None:
    """Write the session's mode file from the last mode in its transcript."""
    # XDG Base Directory: unset or empty XDG_STATE_HOME means ~/.local/state.
    xdg_state: str = os.environ.get("XDG_STATE_HOME", "")
    state_home: Path = (Path(xdg_state) if xdg_state != ""
                        else Path.home() / ".local/state")
    state: Path = state_home / "claude-mode" / data["session_id"]
    if state.exists():
        return

    mode: str | None = None
    with open(data["transcript_path"]) as lines:
        for line in lines:
            # Most lines are not hook context: skip their JSON parse.
            if "hook_additional_context" not in line:
                continue
            attachment: dict = json.loads(line).get("attachment", {})
            if (attachment.get("type") != "hook_additional_context"
                    or attachment.get("hookEvent") != "UserPromptSubmit"):
                continue
            for text in attachment.get("content", []):
                found = re.fullmatch(r"0rwx mode: (READ|WRITE|EXECUTE)", text)
                if found is not None:
                    mode = found.group(1)

    if mode is not None:
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(mode + "\n")


try:
    restore_mode(json.load(sys.stdin))
except (OSError, ValueError):
    # No transcript yet (a new session, a fork made with --fork-session) or a
    # line that does not decode: the session stays in READ.
    pass
