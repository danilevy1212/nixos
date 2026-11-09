"""SessionEnd hook: drop the session's 0rwx mode file so the next session
starts in READ. https://code.claude.com/docs/en/hooks#sessionend
The file lives under $XDG_STATE_HOME/claude-mode, named by session_id.
"""
import json
import os
import sys
from pathlib import Path

data: dict = json.load(sys.stdin)
# XDG Base Directory: unset or empty XDG_STATE_HOME means ~/.local/state.
xdg_state: str = os.environ.get("XDG_STATE_HOME", "")
state_home: Path = (Path(xdg_state) if xdg_state != ""
                    else Path.home() / ".local/state")
state: Path = state_home / "claude-mode" / data["session_id"]
state.unlink(missing_ok=True)
