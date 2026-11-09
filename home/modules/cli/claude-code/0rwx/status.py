"""statusLine: the 0rwx mode (https://0rwx.com) in colour, then the model.

Claude Code pipes the session JSON to stdin and shows stdout verbatim, ANSI
included: https://code.claude.com/docs/en/statusline
The mode file lives under $XDG_STATE_HOME/claude-mode, named by session_id;
absent means READ.
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
mode: str = state.read_text().strip() if state.exists() else "READ"
model: str = data.get("model", {}).get("display_name", "")
color: str = {"READ": "\033[32m", "WRITE": "\033[33m"}.get(mode, "\033[31m")
print(f"{color}{mode}\033[0m · {model}")
