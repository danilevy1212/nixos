{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  username = userConfig.username;
  isLinux = pkgs.stdenv.isLinux;
in {
  # Sorry, Stallman
  nixpkgs.config.allowUnfree = true;

  nix =
    {
      settings = {
        trusted-users = ["root" username];
        # Protect disk space
        auto-optimise-store = true;
      };
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      # Automatic garbage collection
      gc =
        {
          automatic = true;
          options = "--delete-older-than 15d";
        }
        // lib.optionalAttrs isLinux {
          # systemd timer options (NixOS only)
          persistent = true;
          randomizedDelaySec = "15m";
        };
      # Store optimisation
      optimise =
        {
          automatic = true;
        }
        // lib.optionalAttrs isLinux {
          persistent = true;
        };
    }
    // lib.optionalAttrs isLinux {
      # Darwin manages its own nix package
      package = pkgs.nixVersions.stable;
    };

  # Default shell
  programs.zsh.enable = true;

  environment = {
    variables = {
      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which could
      # cause race conditions.
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";

      # EDITOR
      EDITOR = "nvim";
    };
    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      k = "kubectl";
    };
    # Ensure all downloaded packages have auto completion info
    pathsToLink = ["/share/zsh"];
  };
}
