{
  config,
  lib,
  pkgs,
  ...
}: let
  isWork = config.userConfig.isWork;
  agents = import ../agents/shared.nix {inherit lib pkgs;};
  small_model =
    if isWork
    then "github-copilot/claude-haiku-4.5"
    else "opencode/claude-haiku-4.5";
  thinking_model =
    if isWork
    then "github-copilot/claude-sonnet-5"
    else "opencode/qwen3.6-plus";
  building_model =
    if isWork
    then "dev-slop/qwen3.6:35b"
    else "opencode/qwen3.6-plus";
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

    xdg.configFile."opencode/tui.jsonc" = {
      text = ''
        {
          "$schema": "https://opencode.ai/tui.json",
          "theme": "nord",
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
          "lsp": true,
          "small_model": "${small_model}",
          "plugin": [],
          "provider": {
            "github-copilot": {
              "models": {
                "claude-sonnet-5": {
                    "proofreader": {
                     "reasoningEffort": "low"
                    }
                  }
                }
              },
            "opencode": {
              "models": {}
            },
            "lmstudio": {
              "npm": "@ai-sdk/openai-compatible",
              "name": "LM Studio (local)",
              "options": {
                "baseURL": "http://127.0.0.1:1234/v1",
                "max_tokens": 64000
              }
            }${
          if isWork
          then ''            ,
                      "ollama-studio": {
                        "npm": "@ai-sdk/openai-compatible",
                        "name": "Ollama (Studio)",
                        "options": {
                          "baseURL": "http://10.254.3.199:11434/v1",
                          "num_ctx": 128000
                        },
                        "models": {
                          "glm-4.7-flash:q8_0": {
                            "name": "GLM 4.7 Flash"
                          }
                        }
                      },
                      "dev-slop": {
                        "npm": "@ai-sdk/openai-compatible",
                        "name": "Dev (SLOP)",
                        "options": {
                          "baseURL": "https://dev.slop.chaska1.gravwell.space/v1",
                        },
                        "models": {
                          "qwen3-coder-next:q8_0": {
                            "name": "Qwen 3 Coder"
                          },
                          "devstral-2:123b": {
                            "name": "Devstral 2"
                          },
                          "qwen3.6:35b": {
                            "name": "Qwen 3.6 (small)"
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
      # Allow opencode to do websearches using exa
      OPENCODE_ENABLE_EXA = "1";
      # Allow opencode to run lsp servers
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "1";
    };
    # TODO  Testing for now, I can always add an auto-installer later
    home.packages = with pkgs; [openspec];
  };
}
