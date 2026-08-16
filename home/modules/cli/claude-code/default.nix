{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.userConfig.modules.cli;
  isWork = config.userConfig.isWork;
  agents = import ../agents/shared.nix {inherit lib pkgs;};
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in {
  config = lib.mkIf (cfg.enable && cfg.agents.enable) {
    programs.claude-code = {
      enable = true;

      # ~/.claude/CLAUDE.md
      context = agents.rulesText;

      # ~/.claude/settings.json
      settings = {
        permissions = {
          ask =
            ["Edit" "Write" "NotebookEdit" "Bash(dangerouslyDisableSandbox:true)"]
            ++ agents.claudeBashAsk;
          allow = agents.claudeBashAllow ++ ["WebFetch"] ++ agents.claudeAmplenoteAllow;
          deny = ["Read(**/.env)" "Read(./secrets/**)"];
          disableBypassPermissionsMode = "disable";
          disableAutoMode = "disable";
        };
        includeCoAuthoredBy = false;
        model = "opus[1m]";
        effortLevel = "xhigh";

        # Push notifications reach the phone from any client: terminal, Desktop, ACP.
        # preferredNotifChannel is left unset because it works only in a terminal.
        remoteControlAtStartup = true;
        inputNeededNotifEnabled = true;
        agentPushNotifEnabled = true;

        # OS-level (seatbelt or bubblewrap) sandbox for Bash.
        # CAUTION: Keep these keys nested. At the top level of `settings`, Claude
        # Code drops them without warning.
        sandbox = {
          enabled = true;

          # If the sandbox cannot start, stop the session. The escape hatch is
          # separate: allowUnsandboxedCommands defaults true, so those still prompt.
          failIfUnavailable = true;

          # macOS only. Without it the sandbox blocks com.apple.trustd.agent, so TLS
          # certificate validation fails (OSStatus -26276). Breaks gh, go, and curl.
          enableWeakerNetworkIsolation = isDarwin;

          filesystem.allowWrite = [
            "~/Library/Caches/go-build" # GOCACHE (darwin)
            "~/.cache/go-build" # GOCACHE (linux/XDG)
            "~/.cache/go" # GOPATH → GOMODCACHE
            "~/.cache/nix" # nix fetcher/eval caches; XDG on darwin too, so no split
          ];

          network.allowedDomains = [
            "api.github.com"
            "github.com"
            "*.githubusercontent.com"
            "proxy.golang.org"
            "sum.golang.org"
          ];

          # Deny rules for Read and Edit do not reach subprocesses. These rules do.
          credentials.files = [
            {
              path = "~/.ssh";
              mode = "deny";
            }
          ];
        };

        # Uses a git source. The `marketplaces` option emits local dirs only.
        extraKnownMarketplaces = {
          claude-plugins-official = {
            source = {
              source = "git";
              url = "https://github.com/anthropics/claude-plugins-official.git";
            };
          };
        };
      };

      # ~/.claude/commands/commit.md
      commands = {
        commit = ''
          ---
          allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
          description: Create a git commit matching this repo's conventions
          ---
          Analyze the staged changes, review recent history for the repo's commit-message style
          (scoping, length, conventional-commit patterns), then create a single atomic commit that
          follows those conventions.
        '';

        # ~/.claude/commands/review.md — shared prose lives in agents/shared.nix
        review =
          ''
            ---
            allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Read, Grep, Glob
            description: Review a PR — severity-ranked, actionable-only findings
            ---
          ''
          + agents.reviewCommandProse;
      };

      # ~/.claude/skills/claude-code-home-manager/.mcp.json
      mcpServers = {
        mcphub = {
          type = "http";
          url = "http://10.0.0.202:3000/mcp";
          enabled = !isWork;
        };

        # no `{file:}` in claude; shell out to read the header from opencode's secret at launch.
        # native command-based headers: https://code.claude.com/docs/en/mcp#use-dynamic-headers-for-custom-authentication
        amplenote = {
          type = "stdio";
          command = "sh";
          args = [
            "-c"
            ''npx -y mcp-remote@0.1.38 http://127.0.0.1:39377/mcp --header "$(cat ~/.config/opencode/secrets/amplenote-mcp.txt)"''
          ];
        };
      };

      # ~/.claude/skills/claude-code-home-manager/.lsp.json
      lspServers = {
        go = {
          command = lib.getExe pkgs.gopls;
          args = [
            "serve"
          ];
          extensionToLanguage = {
            ".go" = "go";
          };
        };
      };

      # ~/.claude/skills/*
      inherit (agents) skills;
    };

    # Sandbox backend on Linux. Claude Code needs both on PATH, and
    # failIfUnavailable makes a missing one a hard startup failure.
    home.packages = lib.optionals (!isDarwin) [
      pkgs.bubblewrap
      pkgs.socat # network proxying for network.allowedDomains
    ];
  };
}
