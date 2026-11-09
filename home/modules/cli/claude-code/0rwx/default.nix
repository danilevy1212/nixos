# 0rwx modes (https://0rwx.com) for Claude Code: READ (default), WRITE, EXECUTE.
# One script per settings entry. Each finds the session's mode file on its own
# under $XDG_STATE_HOME/claude-mode (XDG Base Directory spec); absent means READ.
# writePython3Bin runs flake8 at build time.
{pkgs}: let
  entry = name: let
    bin = pkgs.writers.writePython3Bin "claude-mode-${name}" {} (builtins.readFile (./. + "/${name}.py"));
  in {
    type = "command";
    command = "${bin}/bin/claude-mode-${name}";
  };
in {
  # settings.hooks
  hooks = {
    UserPromptSubmit = [{hooks = [(entry "prompt")];}];
    PreToolUse = [
      {
        matcher = "Edit|Write|NotebookEdit";
        hooks = [(entry "gate")];
      }
    ];
    SessionEnd = [{hooks = [(entry "end")];}];
  };
  # settings.statusLine
  statusLine = entry "status";

  # ~/.claude/commands/{read,write,execute}.md — the mode switches. The
  # UserPromptSubmit hook records the mode; these carry the request.
  # disable-model-invocation keeps the switch in the user's hands.
  commands = {
    read = ''
      ---
      description: Switch to READ mode (0rwx). I write the code; Claude reads, verifies, and keeps the record.
      disable-model-invocation: true
      ---
      Mode switch: READ. From here on, edits are denied except plan files, memory, and scratchpad
      scripts. Name the file, the location, and the exact change instead. Modes are defined in
      CLAUDE.md under Modes.
    '';
    write = ''
      ---
      description: Switch to WRITE mode (0rwx), optionally with a scope. Claude writes; I read the diff.
      argument-hint: [scope]
      disable-model-invocation: true
      ---
      Mode switch: WRITE. $ARGUMENTS

      Write what the request covers, bounded by the scope above when there is one; edits prompt
      as usual. Rule 2 holds: nothing is committed or pushed without a yes. Modes are defined in
      CLAUDE.md under Modes.
    '';
    execute = ''
      ---
      description: Switch to EXECUTE mode (0rwx), optionally with a scope. Claude takes it end to end; I curate.
      argument-hint: [scope]
      disable-model-invocation: true
      ---
      Mode switch: EXECUTE. $ARGUMENTS

      Take the request end to end without pausing between steps, bounded by the scope above when
      there is one; edits inside the working directory run without prompts. Rule 2 holds: nothing
      is committed or pushed without a yes. Modes are defined in CLAUDE.md under Modes.
    '';
  };
}
