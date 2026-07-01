{
  config,
  lib,
  ...
}: let
  isWork = config.userConfig.isWork;
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
      context = builtins.readFile ./RULES.md;
      commands = {
        commit_message = ''
          # Commit Message

          Analyze the staged (cached) changes and create an appropriate commit message. Follow this process:

          1. First, examine the staged changes using `git diff --staged` to understand what will be committed
          2. Review recent commit history to understand the repository's commit message style and scoping conventions
          3. Analyze the nature of the staged changes (new feature, bug fix, refactor, docs, etc.)
          4. Draft a commit message that follows the established patterns

          After writing the commit message, automatically execute the commit using the message you created.

          Use the repository's existing commit message format. Pay attention to:
          - Scoping (if used in this repo)
          - Line length limits
          - Multi-line format when appropriate
          - Conventional commit patterns (if used)
        '';
      };
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
            },
            "execute": {
              "model": "${small_model}",
              "mode": "subagent",
              "description": "Executes the plans layed out by the plan agent.",
              "prompt": "You are the Execute subagent. Carry out concrete actions delegated by the Plan agent using the shared conversation context. Do not re‑plan; follow the given steps and constraints. Respect repository rules and permissions. Be concise: state what you did, the result, and whether anything is blocked. Ask only when a blocker prevents progress. Acknowledge each delegated step after completing it before moving forward.",
              "tools": {
                "*": true
              }
            }
          },
          "permission": {
            "edit": "ask",
            "external_directory": {
              "*": "ask",
              "~/Projects/workspace/**": "allow"
            },
            "bash": {
               "*": "ask",
              "git status*": "allow",
              "git log*": "allow",
              "git diff*": "allow",
              "git rev-parse*": "allow",
              "git remote -v": "allow",
              "git branch -a": "allow",
              "grep*": "allow",
              "rg*": "allow",
              "head*": "allow",
              "gh issue view*": "allow",
              "gh search*": "allow",
              "gh pr view*": "allow",
              "go list*": "allow",
              "which*": "allow",
              "cat*": "allow",
              "ls*": "allow",
              "nix flake show*": "allow",
              "echo*": "allow",
              "sed -n*": "allow"
            },
            "webfetch": "allow",
            "amplenote_*": "ask",
            "amplenote_getNoteMetadata": "allow",
            "amplenote_getNoteContent": "allow",
            "amplenote_getNoteAttachments": "allow",
            "amplenote_getNoteImages": "allow",
            "amplenote_getAttachmentURL": "allow",
            "amplenote_getMoodRatings": "allow",
            "amplenote_getCompletedTasks": "allow",
            "amplenote_filterNotes": "allow",
            "amplenote_searchNotes": "allow"
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
  };
}
