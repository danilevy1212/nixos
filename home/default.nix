{
  lib,
  config,
  userConfig ? null,
  ...
}: let
  modules = [
    # I cannot live without you, my one true love...
    "emacs"

    # My guilty pleasure
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
  assert assertMsg (isAttrs userConfig) "You must pass a `userConfig' attrSet to `home-manager.extraSpecialArgs'"; {
    options.userConfig = mkOption {
      description = "home-manager user configuration";
      default = userConfig;
      # TODO  why not `type = types.attrs`?
      type = with types;
        submodule {
          options = {
            username = mkOption {
              type = types.str;
              example = "dlevym";
              description = "User account name.";
            };
          };
        };
    };
    config = {
      home = rec {
        username = cfg.username;
        homeDirectory = "/home/${username}";
        stateVersion = config.home.version.release;
        # Make XDG Base Dir. compliant
        sessionPath = [
          "$HOME/.local/bin"
        ];
      };

      # Be quiet, will you?
      news.display = "notify";

      # Respect XDG base directory specification
      xdg = {
        enable = true;
        mimeApps = {
          enable = true;
        };
      };
    };

    # Modularize! Never compromise! 😎
    imports = moduleImports;
  }
