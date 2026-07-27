{
  lib,
  pkgs,
}: let
  isDarwin = pkgs.stdenv.isDarwin;

  # OS-specific privilege-escalation rule, appended to the shared prose.
  platformNote =
    if isDarwin
    then ''
      # Privilege Escalation

      - This machine is macOS. When a command needs elevated privileges, use `sudo` directly.
    ''
    else ''
      # Privilege Escalation

      - This machine is Linux. Do not use `sudo`; when elevation is needed, use `pkexec` instead.
    '';

  # Read-only command prefixes safe to auto-allow for BOTH assistants.
  readonlyBash = [
    "git status"
    "git log"
    "git diff"
    "git show"
    "git rev-parse"
    "git remote -v"
    "git branch -a"
    "grep"
    "rg"
    "head"
    "cat"
    "ls"
    "find"
    "which"
    "sort"
    "sed -n"
    "echo"
    "gh issue view"
    "gh issue list"
    "gh pr view"
    "gh pr diff"
    "gh pr list"
    "gh search"
    "gh repo view"
    "go list"
    "nix flake show"
    "nix flake metadata"
    "nix eval"
  ];
  # Read-only amplenote MCP tools safe to auto-allow for BOTH assistants.
  amplenoteReadonly = [
    "getNoteMetadata"
    "getNoteContent"
    "getNoteAttachments"
    "getNoteImages"
    "getAttachmentURL"
    "getMoodRatings"
    "getCompletedTasks"
    "filterNotes"
    "searchNotes"
  ];
in rec {
  inherit readonlyBash;

  # Shared rules prose + the platform-specific privilege rule.
  rulesText = builtins.readFile ./RULES.md + "\n" + platformNote;

  # opencode `permission.bash` requires "*" FIRST. `builtins.toJSON` sorts keys
  # (Nix attrsets are unordered), so it can't be used here. Nix LISTS preserve
  # order — render an ordered JSONC object string with "*" prepended.
  opencodeBashBlock = let
    entries = [''"*": "ask"''] ++ map (c: ''"${c}*": "allow"'') readonlyBash;
  in
    "{ " + lib.concatStringsSep ", " entries + " }";

  # Claude Code `permissions.allow` is a JSON ARRAY — order is preserved natively.
  claudeBashAllow = map (c: "Bash(${c}:*)") readonlyBash;

  # opencode names MCP tools `<server>_<tool>`. Same ordering constraint as
  # opencodeBashBlock — "*" catch-all first — so render ordered JSONC entries,
  # spliced in as siblings under `permission`.
  opencodeAmplenotePerms = let
    entries =
      [''"amplenote_*": "ask"'']
      ++ map (t: ''"amplenote_${t}": "allow"'') amplenoteReadonly;
  in
    lib.concatStringsSep ",\n            " entries;

  # Claude Code names them `mcp__<server>__<tool>`; home-manager ships mcpServers
  # as a generated plugin, so the server segment carries a plugin prefix.
  claudeAmplenoteAllow =
    map (t: "mcp__plugin_claude-code-home-manager_amplenote__${t}") amplenoteReadonly;
}
