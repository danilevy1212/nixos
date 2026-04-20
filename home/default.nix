{
  lib,
  config,
  userConfig ? null,
  stable,
  ...
}: let
  modules = [
    # Editor
    "neovim"

    # My Shell configuration.
    "cli"

    # Abandon hope, all that come here.
    "nodejs"

    # What's going on out there?
    "networking"

    # Rust
    "rust"

    # Golang
    "golang"

    # A system admin best friend
    "python"

    # User Interface
    "gui"

    # Normie Apps so I can pretend I am not a nerd.
    "apps"
  ];
  moduleImports = map (x: ./. + "/modules/${x}") modules;
  cfg = config.userConfig;
in
  with lib;
  # pretty print userConfig
  # assert assertMsg false "${builtins.toJSON userConfig}";
  assert assertMsg (isAttrs userConfig) "You must pass a `userConfig' attrSet to `home-manager.extraSpecialArgs'"; {
    options.userConfig = mkOption {
      description = "home-manager user configuration";
      default = userConfig;
      type = with types;
        submodule {
          options = {
            username = mkOption {
              type = types.str;
              example = "dlevym";
              description = "User account name.";
            };
            isWork = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this is a work machine";
            };
          };
        };
    };
    config = {
      home = rec {
        username = cfg.username;
        homeDirectory =
          if stable.stdenv.isLinux
          then "/home/${username}"
          else "/Users/${username}";
        stateVersion = config.home.version.release;
        # Make XDG Base Dir compliant
        sessionPath = [
          "$HOME/.local/bin"
          "/etc/profiles/per-user/${username}/bin"
        ];
      };

      # Be quiet, will you?
      news.display = "notify";

      # Respect XDG base directory specification
      xdg = {
        enable = true;
        mimeApps = {
          enable = stable.stdenv.isLinux;
        };
      };
    };

    # Modularize! Never compromise! 😎
    imports = moduleImports;
  }
