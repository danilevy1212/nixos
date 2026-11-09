"""PreToolUse hook on Edit|Write|NotebookEdit: deny edits in READ, allow them
unprompted in EXECUTE, stay silent in WRITE so the normal ask rules apply.

Claude Code pipes one JSON object to stdin; no output means no decision:
https://code.claude.com/docs/en/hooks#pretooluse-decision-control
The 0rwx mode (https://0rwx.com) file lives under $XDG_STATE_HOME/claude-mode,
named by session_id; absent means READ.
"""
import json
import os
import sys
from fnmatch import fnmatch
from pathlib import Path

data: dict = json.load(sys.stdin)
# XDG Base Directory: unset or empty XDG_STATE_HOME means ~/.local/state.
xdg_state: str = os.environ.get("XDG_STATE_HOME", "")
state_home: Path = (Path(xdg_state) if xdg_state != ""
                    else Path.home() / ".local/state")
state: Path = state_home / "claude-mode" / data["session_id"]
mode: str = state.read_text().strip() if state.exists() else "READ"

tool_input: dict = data.get("tool_input", {})
path: str = tool_input.get("file_path", "")
if path == "":
    path = tool_input.get("notebook_path", "")
decision: dict | None = None

if mode == "READ":
    # The scribe's files stay writable: plan files, Claude's memory directory,
    # and throwaway scripts in the session scratchpad.
    scratch: str = data.get("scratchpad_dir", "")
    scribe: bool = (
        fnmatch(path, "*/.plans/*.md")
        or fnmatch(path, "*/.claude/projects/*/memory/*")
        or (scratch != "" and path.startswith(scratch + "/"))
    )
    if not scribe:
        decision = {
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "READ mode: name the file, the location and the exact change "
                "instead; /write lifts this."),
        }
elif mode == "EXECUTE" and path.startswith(data["cwd"] + "/"):
    # Inside the working directory edits run unprompted; outside it the
    # normal prompt stays.
    decision = {
        "permissionDecision": "allow",
        "permissionDecisionReason": "EXECUTE mode",
    }

if decision is not None:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", **decision}}))
