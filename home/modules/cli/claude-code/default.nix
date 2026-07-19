{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.userConfig.modules.cli;
  isWork = config.userConfig.isWork;
  agents = import ../agents/shared.nix {inherit lib pkgs;};
in {
  config = lib.mkIf (cfg.enable && cfg.agents.enable) {
    programs.claude-code = {
      enable = true;

      # ~/.claude/CLAUDE.md
      context = agents.rulesText;

      # ~/.claude/settings.json
      settings = {
        permissions = {
          ask = ["Edit" "Write" "NotebookEdit"];
          allow = agents.claudeBashAllow ++ ["WebFetch"];
          deny = ["Read(./.env)" "Read(./secrets/**)"];
        };
        includeCoAuthoredBy = false;

        # git source; the `marketplaces` option only emits local dir sources.
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
      };

      # ~/.claude/.mcp.json
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
    };
  };
}
