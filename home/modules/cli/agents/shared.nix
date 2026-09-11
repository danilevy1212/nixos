{
  lib,
  pkgs,
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Privilege-escalation rule for the host OS. rulesText appends it.
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

  # Auto-allowed for BOTH assistants. Anything that can execute code stays out:
  # go build/vet/test (cgo runs at build time), bash, docker, python,
  # awk (system()), gh api (can POST).
  readonlyBash = [
    "git status"
    "git log"
    "git diff"
    "git show"
    "git rev-parse"
    "git remote -v"
    "git branch -a"
    "git branch --show-current"
    "git rev-list"
    "git cat-file"
    "git ls-remote"
    "git merge-tree" # read-only conflict preview
    "git fetch" # refs only, never the worktree
    "grep"
    "rg"
    "head"
    "tail"
    "cat"
    "ls"
    "find"
    "which"
    "uuidgen"
    "sort"
    "uniq"
    "cut"
    "wc"
    "jq"
    "diff"
    "test"
    "pwd"
    "cd"
    "echo"
    "gh issue view"
    "gh issue list"
    "gh pr view"
    "gh pr diff"
    "gh pr list"
    "gh pr checks"
    "gh run view"
    "gh search"
    "gh repo view"
    "go list"
    "gofmt -l" # -w stays prompted
    "nix flake show"
    "nix flake metadata"
    "nix eval"
    "nix-instantiate --parse"
  ];
  # Exec-capable variants of the allowed prefixes. ask outranks allow in both
  # assistants. A single * spans spaces.
  escalateBash = [
    "find * -exec*" # also -execdir
    "find * -ok*" # also -okdir
    "rg --pre*" # --pre executes a preprocessor
    "rg * --pre*"
  ];
  # MCP tools auto-allowed for BOTH assistants.
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
  # Two writing skills and one output style from one repo.
  plainEnglishSrc = pkgs.fetchFromGitHub {
    owner = "b1rdmania";
    repo = "claude-plain-english-skill";
    rev = "1e1501e0e4da21d63b6611e2f258cf28c356a86c"; # v0.6.1
    hash = "sha256-jXo2Yo86PAUNnrwwfe5NW3pfk/AFSKRPzwzDRCq958g=";
  };

  # Each subdir is a self-contained skill: SKILL.md plus the files it loads.
  skills = {
    # Strips AI tics with Orwell/Gowers rules.
    plain-english = "${plainEnglishSrc}/skills/plain-english";
    # Enforces ASD-STE100 (Simplified Technical English).
    simple-english = "${plainEnglishSrc}/skills/simple-english";
  };

  # Skill files read during a run (REFERENCE.md, references/). Both assistants
  # symlink these out of the store, and the read resolves the link first.
  # So the resolved path needs a rule of its own.
  skillStoreDirs = lib.attrValues skills;
in rec {
  inherit readonlyBash;

  rulesText = builtins.readFile ./RULES.md + "\n" + platformNote;

  # Each assistant adds its own frontmatter: allowed-tools for Claude Code, a
  # markdown heading for opencode.
  reviewCommandProse = ''
    Review the pull request in $ARGUMENTS (number or URL). Fetch it with the gh CLI; read
    the surrounding local code when the diff alone isn't enough to judge.

    Report findings ranked by severity: correctness > data loss > security > performance >
    design. For each: what breaks, where (file:line), and the concrete fix, in three
    sentences or fewer. Mark each finding CONFIRMED (you traced the failure path) or
    SPECULATIVE (the author must check). A finding with no actionable is noise: drop it.
    Say nothing about style or formatting unless asked. If the PR is sound, say so in one
    line; do not manufacture findings.
  '';

  # opencode `permission.bash` needs "*" FIRST and escalate entries LAST,
  # because later entries win. `builtins.toJSON` sorts keys, so this renders an
  # ordered JSONC string from Nix lists instead.
  opencodeBashBlock = let
    entries =
      [''"*": "ask"'']
      ++ map (c: ''"${c}*": "allow"'') readonlyBash
      ++ map (c: ''"${c}": "ask"'') escalateBash;
  in
    "{ " + lib.concatStringsSep ", " entries + " }";

  # Claude Code `permissions.allow` is a JSON ARRAY, so it keeps this order.
  claudeBashAllow = map (c: "Bash(${c}:*)") readonlyBash;

  claudeBashAsk = map (c: "Bash(${c})") escalateBash;

  # opencode names MCP tools `<server>_<tool>`. Same ordering constraint as
  # opencodeBashBlock, so these render as ordered JSONC siblings under
  # `permission`.
  opencodeAmplenotePerms = let
    entries =
      [''"amplenote_*": "ask"'']
      ++ map (t: ''"amplenote_${t}": "allow"'') amplenoteReadonly;
  in
    lib.concatStringsSep ",\n            " entries;

  # Claude Code names them `mcp__<server>__<tool>`. home-manager ships mcpServers
  # as a generated plugin, so the server segment carries a plugin prefix.
  claudeAmplenoteAllow =
    map (t: "mcp__plugin_claude-code-home-manager_amplenote__${t}") amplenoteReadonly;

  # Claude Code takes gitignore-style path rules. "//" prefixes an absolute path.
  claudeSkillAllow =
    ["Read(~/.claude/skills/**)"]
    ++ map (d: "Read(/${d}/**)") skillStoreDirs;

  # opencode gates the same reads through `external_directory`, per directory.
  # The consuming block keeps its "*" catch-all first, so these render after it.
  opencodeSkillPerms =
    lib.concatStringsSep ",\n              "
    (map (d: ''"${d}/**": "allow"'')
      (["~/.config/opencode/skills"] ++ skillStoreDirs));

  # The same attrset shape works in either module.
  inherit skills;

  # Claude Code only. Applies the plain-english rules to every response; the
  # skill applies them only when invoked. settings.outputStyle selects it.
  plainEnglishStyle = "${plainEnglishSrc}/output-styles/plain-english.md";
}
