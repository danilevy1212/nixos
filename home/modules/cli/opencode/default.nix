{
  config,
  lib,
  pkgs,
  ...
}: let
  isWork = config.userConfig.isWork;
  hasGui = config.userConfig.modules.gui.enable;
  agents = import ../agents/shared.nix {inherit lib pkgs config;};
  small_model =
    if isWork
    then "ollama-cloud/deepseek-v4.1-flash"
    else "opencode/deepseek-v4.1-flash";
  thinking_model =
    if isWork
    then "ollama-cloud/kimi-k3"
    else "opencode/kimi-k3";
  building_model =
    if isWork
    then "ollama-cloud/kimi-k2.7-code"
    else "opencode/muse-spark-1.3-contributor-free";
  cfg = config.userConfig.modules.cli;
in {
  config = lib.mkIf (cfg.enable && cfg.agents.enable) {
    # Vibing and coding
    programs.opencode = {
      enable = true;
      context = agents.rulesText;
      commands = {
        # ~/.config/opencode/command/commit_message.md — shared prose lives in agents/shared.nix
        commit_message =
          ''
            # Commit Message

          ''
          + agents.commitCommandProse;

        # ~/.config/opencode/command/review.md — shared prose lives in agents/shared.nix
        review =
          ''
            # Review

          ''
          + agents.reviewCommandProse;
      };
      # ~/.config/opencode/skills/*
      inherit (agents) skills;
    };

    xdg.configFile."opencode/cli.json" = {
      text = ''
        {
          "$schema": "https://opencode.ai/v2/cli.json",
          "theme": {
            "name": "nord"
          },
          "keybinds": {
            "leader": "ctrl+x"
          }
        }
      '';
    };

    xdg.configFile."opencode/opencode.jsonc" = {
      text = ''
        {
          "$schema": "https://opencode.ai/config.json",
          "small_model": "${small_model}",
          "plugin": [],
          "provider": {
            "opencode": {
              "models": {}
            }${
          if isWork
          then ''            ,
                      "dev-slop": {
                        "npm": "@ai-sdk/openai-compatible",
                        "name": "Dev (SLOP)",
                        "options": {
                          "baseURL": "https://dev.slop.chaska1.gravwell.space/v1",
                        },
                        "models": {
                          "qwen3.8:27b": {
                            "name": "Qwen 3.8 (small)"
                          }
                        }
                      }
          ''
          else ""
        }
          },
          "agent": {
            "plan": {
              "model": "${thinking_model}"
            },
            "build": {
              "model": "${building_model}"
            }
          },
          "permission": {
            "edit": "ask",
            "external_directory": {
              "*": "ask",
              "~/Projects/workspace/**": "allow",
              ${agents.opencodeSkillPerms}
            },
            "bash": ${agents.opencodeBashBlock},
            "webfetch": "allow",
            ${agents.opencodeAmplenotePerms}
          },
          "mcp": {
            "mcphub": {
              "enabled": ${builtins.toJSON (!isWork)},
              "type": "remote",
              "url": "http://10.0.0.202:3000/mcp"
            },
            "amplenote": {
              "enabled": true,
              "type": "local",
              "command": [
                  "npx",
                  "-y",
                  "mcp-remote@0.1.38",
                  "http://127.0.0.1:39377/mcp",
                  "--header",
                  "{file:~/.config/opencode/secrets/amplenote-mcp.txt}"
              ]
            }
          }
        }
      '';
    };
    home.sessionVariables = {
      SMALL_MODEL = "${small_model}";
    };
    home.packages = with pkgs;
      [
        openspec
      ]
      ++ lib.optional hasGui opencode-desktop;
  };
}
