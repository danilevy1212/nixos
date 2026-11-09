{
  lib,
  pkgs,
  config,
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

  # Adds a `git -C <dir> <sub>` twin for each `git <sub>` entry, since the
  # prefix match misses the -C form. The * spans spaces, so the outward list
  # needs the same twins to keep `git -C x push ... status` prompted.
  withGitC = cmds:
    cmds
    ++ map (c: "git -C * ${lib.removePrefix "git " c}")
    (lib.filter (lib.hasPrefix "git ") cmds);

  # Auto-allowed for BOTH assistants.
  readonlyBash = withGitC [
    # git: inspection only. `git diff` also matches diff-tree and diff-index.
    # Short branch flags stay out: `git branch -v` would also pass
    # `git branch -v -D <name>`.
    "git status"
    "git log"
    "git diff"
    "git show"
    "git rev-parse"
    "git remote -v"
    "git remote show"
    "git remote get-url"
    "git branch -a"
    "git branch --show-current"
    "git branch --list"
    "git branch --contains"
    "git branch --merged"
    "git branch --no-merged"
    "git rev-list"
    "git cat-file"
    "git ls-remote"
    "git ls-files"
    "git ls-tree"
    "git blame"
    "git grep"
    "git describe"
    "git shortlog"
    "git reflog show"
    "git stash list"
    "git stash show"
    "git worktree list"
    "git tag -l"
    "git tag --list"
    "git config --get"
    "git config --list"
    "git check-ignore"
    "git for-each-ref"
    "git name-rev"
    "git cherry"
    "git range-diff"
    "git count-objects"
    "git merge-tree" # read-only conflict preview
    "git fetch" # refs only, never the worktree
    # files and text
    "grep"
    "rg"
    "head"
    "tail"
    "cat"
    "ls"
    "find"
    "which"
    "uuidgen"
    "sort" # -o writes a file: escalated below
    "uniq"
    "cut"
    "wc"
    "jq"
    "diff"
    "test"
    "pwd"
    "cd"
    "echo"
    "printf"
    "true"
    "false"
    "type"
    "command -v"
    "sed -n" # print only; -i forms escalated below
    "tr"
    "rev"
    "column"
    "paste"
    "comm"
    "fold"
    "nl"
    "tac"
    "xxd"
    "od"
    "hexdump"
    "strings"
    "stat"
    "du"
    "df"
    "realpath"
    "readlink"
    "basename"
    "dirname"
    "date"
    "seq"
    "shasum"
    "sha256sum"
    "md5sum"
    "md5"
    "fd" # -x/--exec escalated below
    # system, read-only
    "uname"
    "hostname"
    "whoami"
    "id"
    "uptime"
    "nproc"
    "dig"
    # macOS
    "sw_vers"
    "diskutil list"
    "diskutil info"
    "system_profiler"
    "defaults read"
    "launchctl list"
    "launchctl print"
    "pmset -g"
    "mdfind"
    "otool"
    "codesign -d"
    "plutil -p"
    # Linux
    "lsblk"
    "lscpu"
    "free"
    "journalctl" # --vacuum*/--rotate escalated below
    "systemctl status"
    "systemctl show"
    "systemctl cat"
    "systemctl list-units"
    "systemctl list-unit-files"
    "systemctl list-timers"
    "systemctl is-active"
    "systemctl is-enabled"
    # gh: reads only
    "gh issue view"
    "gh issue list"
    "gh issue status"
    "gh pr view"
    "gh pr diff"
    "gh pr list"
    "gh pr status"
    "gh pr checks"
    "gh run view"
    "gh run list"
    "gh workflow list"
    "gh workflow view"
    "gh release list"
    "gh release view"
    "gh search"
    "gh repo view"
    "gh repo list"
    "gh label list"
    "gh auth status"
    # toolchains: nothing that compiles or runs project code
    "go list"
    "go version"
    "go env" # -w/-u write the config: escalated below
    "go doc"
    "go mod graph"
    "go mod why"
    "go mod verify"
    "gofmt -l" # -w stays prompted
    "gofmt -d"
    "cargo metadata"
    "cargo tree"
    "cargo --version"
    "npm ls"
    "npm view"
    "npm --version"
    "node --version"
    "python3 --version"
    "nix flake show"
    "nix flake metadata"
    "nix eval"
    "nix-instantiate --parse"
    "nix path-info"
    "nix derivation show"
    "nix log"
    "nix why-depends"
    "nix search"
    "nix hash"
    "nix config show"
    "nix store ls"
    "nix-store -q"
    "nix-store --query"
    "alejandra --check"
    "alejandra -c"
    # containers: inspection only
    "docker ps"
    "docker images"
    "docker logs"
    "docker inspect"
    "docker version"
    "docker info"
    "docker compose ps"
    "docker compose logs"
    "docker compose config"
  ];
  # Write- or exec-capable variants of the allowed prefixes. ask outranks allow
  # in both assistants. A single * spans spaces.
  escalateBash = [
    "find * -exec*" # also -execdir
    "find * -ok*" # also -okdir
    "rg --pre*" # --pre executes a preprocessor
    "rg * --pre*"
    "sed -i*" # in-place edit, also -i.bak
    "sed -ni*"
    "sed * -i*"
    "sed --in-place*"
    "sed * --in-place*"
    "sort -o*" # writes the output file
    "sort * -o*"
    "sort --output*"
    "sort * --output*"
    "fd -x*" # runs a command per result
    "fd -X*"
    "fd --exec*"
    "fd * -x*"
    "fd * -X*"
    "fd * --exec*"
    "go env -w*" # writes the go env file
    "go env -u*"
    "journalctl *--vacuum*" # deletes journal files
    "journalctl *--rotate*"
  ];
  # Commits, pushes, and GitHub writes. Prompted even where a local allow
  # would pass them: ask outranks allow.
  outwardBash = withGitC [
    "git commit"
    "git push"
    "gh pr create"
    "gh pr comment"
    "gh pr edit"
    "gh pr review"
    "gh pr merge"
    "gh pr ready"
    "gh pr close"
    "gh issue create"
    "gh issue comment"
    "gh issue edit"
    "gh issue close"
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

  commitCommandProse = ''
    Analyze the staged changes, review recent history for the repo's commit-message style
    (scoping, length, conventional-commit patterns), then create a single atomic commit that
    follows those conventions.
  '';

  # opencode v2 `permissions` is an ordered list and the last matching rule
  # wins, so the catch-all comes first and escalations last. The shell action is
  # `shell`; a resource ending in " *" also matches the bare command. MCP tools
  # are actions named `<server>_<tool>` with resource "*".
  opencodeRule = action: resource: effect: {inherit action resource effect;};
  opencodePermissions =
    [(opencodeRule "shell" "*" "ask")]
    ++ map (c: opencodeRule "shell" "${c} *" "allow") readonlyBash
    ++ map (c: opencodeRule "shell" c "ask") escalateBash
    ++ map (c: opencodeRule "shell" "${c} *" "ask") outwardBash
    ++ [
      (opencodeRule "edit" "*" "ask")
      (opencodeRule "webfetch" "*" "allow")
      (opencodeRule "external_directory" "*" "ask")
      (opencodeRule "external_directory" "~/Projects/*" "allow")
    ]
    ++ map (d: opencodeRule "external_directory" "${d}/*" "allow")
    (["~/.config/opencode/skills"] ++ skillStoreDirs)
    ++ [(opencodeRule "amplenote_*" "*" "ask")]
    ++ map (t: opencodeRule "amplenote_${t}" "*" "allow") amplenoteReadonly;

  # 0rwx modes as opencode primary agents; `default_agent` selects `read`.
  # Agent rules append after the global list, so each restates only `edit`.
  # opencode has no scratchpad, so READ's throwaway scripts live under /tmp.
  opencodeAgents = {
    read = {
      description = "READ (0rwx): I write the code; the agent reads and verifies. Edits denied except plan files and /tmp.";
      mode = "primary";
      permissions = [
        (opencodeRule "edit" "*" "deny")
        (opencodeRule "edit" "*.plans/*.md" "allow")
        (opencodeRule "edit" "/tmp/*" "allow")
        (opencodeRule "edit" "/private/tmp/*" "allow")
      ];
    };
    write = {
      description = "WRITE (0rwx): the agent writes; I read the diff. Edits prompt.";
      mode = "primary";
      permissions = [(opencodeRule "edit" "*" "ask")];
    };
    execute = {
      description = "EXECUTE (0rwx): the agent takes the request end to end; I curate. Edits run unprompted.";
      mode = "primary";
      permissions = [(opencodeRule "edit" "*" "allow")];
    };
  };

  # Claude Code `permissions.allow` is a JSON ARRAY, so it keeps this order.
  claudeBashAllow = map (c: "Bash(${c}:*)") readonlyBash;

  claudeBashAsk =
    map (c: "Bash(${c})") escalateBash
    ++ map (c: "Bash(${c}:*)") outwardBash;

  # Claude Code names them `mcp__<server>__<tool>`. home-manager ships mcpServers
  # as a generated plugin, so the server segment carries a plugin prefix.
  claudeAmplenoteAllow =
    map (t: "mcp__plugin_claude-code-home-manager_amplenote__${t}") amplenoteReadonly;

  # Claude Code takes gitignore-style path rules. "//" prefixes an absolute path.
  claudeSkillAllow =
    ["Read(~/.claude/skills/**)"]
    ++ map (d: "Read(/${d}/**)") skillStoreDirs;

  # The same attrset shape works in either module.
  inherit skills;

  # Claude Code only. Applies the plain-english rules to every response; the
  # skill applies them only when invoked. settings.outputStyle selects it.
  plainEnglishStyle = "${plainEnglishSrc}/output-styles/plain-english.md";
}
