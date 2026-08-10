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
  # Anything that can execute code stays out: go build/vet/test (cgo runs at
  # build time), bash, docker, python, awk (system()), gh api (can POST).
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
  # Exec-capable variants of allowed prefixes, escalated back to a prompt
  # (ask outranks allow in both assistants; a single * spans spaces).
  escalateBash = [
    "find * -exec*" # also -execdir
    "find * -ok*" # also -okdir
    "rg --pre*" # --pre executes a preprocessor
    "rg * --pre*"
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
  # Plain-English skill: strips AI tics, applies Orwell/Gowers rules.
  # Repo root is the skill dir (SKILL.md + the REFERENCE.md it loads).
  plainEnglishSkill = pkgs.fetchFromGitHub {
    owner = "b1rdmania";
    repo = "claude-plain-english-skill";
    rev = "43af25e6b03ea7356648b48ae2a2280502e6594f"; # v0.3.0
    hash = "sha256-VnwmsWLqP5yKjEXBruoT3JwT6/hxuk3dbtKAu/8rAGs=";
  };

  # Plain-English STE skill: enforces ASD-STE100 Simplified Technical English.
  # SKILL.md lives under skills/simple-english/, not the repo root.
  plainEnglishSteSkill = "${pkgs.fetchFromGitHub {
    owner = "AminBlg";
    repo = "SimpleEnglish";
    rev = "eaa7fded155ad47e5baa072ebae4c70d1254e9e2"; # v1.2.0
    hash = "sha256-62IdviEpLgMXYzJwjdM6G7VVJtyaAHGhQGHw2oFCAHE=";
  }}/skills/simple-english";
in rec {
  inherit readonlyBash;

  # Shared rules prose + the platform-specific privilege rule.
  rulesText = builtins.readFile ./RULES.md + "\n" + platformNote;

  # Shared /review command prose; each assistant wraps it with its own
  # frontmatter (Claude Code needs allowed-tools; opencode a markdown heading).
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

  # opencode `permission.bash` requires "*" FIRST and escalate entries LAST
  # (later entries win). `builtins.toJSON` sorts keys, so render an ordered
  # JSONC object string from Nix lists instead.
  opencodeBashBlock = let
    entries =
      [''"*": "ask"'']
      ++ map (c: ''"${c}*": "allow"'') readonlyBash
      ++ map (c: ''"${c}": "ask"'') escalateBash;
  in
    "{ " + lib.concatStringsSep ", " entries + " }";

  # Claude Code `permissions.allow` is a JSON ARRAY — order is preserved natively.
  claudeBashAllow = map (c: "Bash(${c}:*)") readonlyBash;

  # Claude Code `permissions.ask` entries; ask outranks allow regardless of order.
  claudeBashAsk = map (c: "Bash(${c})") escalateBash;

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

  # Skills shared by both assistants; same attrset shape in either module.
  skills = {
    plain-english = plainEnglishSkill;
    plain-english-STE = plainEnglishSteSkill;
  };
}
