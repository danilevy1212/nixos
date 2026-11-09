"""UserPromptSubmit hook: record a /read, /write or /execute switch and tell
Claude the current 0rwx mode (https://0rwx.com).

Claude Code pipes one JSON object to stdin and reads the JSON reply:
https://code.claude.com/docs/en/hooks#userpromptsubmit
The mode file lives under $XDG_STATE_HOME/claude-mode, named by session_id;
absent means READ.
"""
import json
import os
import re
import sys
from pathlib import Path

data: dict = json.load(sys.stdin)
# XDG Base Directory: unset or empty XDG_STATE_HOME means ~/.local/state.
xdg_state: str = os.environ.get("XDG_STATE_HOME", "")
state_home: Path = (Path(xdg_state) if xdg_state != ""
                    else Path.home() / ".local/state")
state: Path = state_home / "claude-mode" / data["session_id"]

# `prompt` is the line as typed: a slash command arrives unexpanded.
switch = re.match(r"^/(read|write|execute)(\s|$)", data["prompt"])
if switch is not None:
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(switch.group(1).upper() + "\n")

mode: str = state.read_text().strip() if state.exists() else "READ"
# additionalContext reaches Claude beside the prompt, as a system reminder.
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": f"0rwx mode: {mode}",
}}))
