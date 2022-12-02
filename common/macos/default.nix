{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.users.dlevy = import ./../../home/home.nix;
  users.users.dlevy.home = "/Users/dlevy";

  # List packages installed in system profile.
  environment = {
    systemPackages = with pkgs; [
      iterm2
      maven
      docker
    ];
    # Add homebrew to PATH
    systemPath = [
      "/opt/homebrew/bin"
    ];
    variables = {
      LIQUIBASE_HOME = "/opt/homebrew/opt/liquibase/libexec";
    };
  };

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      # emacs/fonts module
      # Fonts
      emacs-all-the-icons-fonts
      ## Emacs
      sarasa-gothic
      dejavu_fonts
      symbola
      noto-fonts
      (import ./../../home/modules/emacs/quivera.nix {inherit pkgs;})
      # Terminal
      victor-mono
    ];
  };

  # Brew packages
  homebrew = {
    enable = true;
    brewPrefix = "/opt/homebrew/bin/";
    brews = [
      "golangci-lint" # emacs/golang module
      "pyenv"
      "jenv"
      "maven"
      "liquibase"
      "sass/sass/sass"
      "watchman"
      "neofetch"
      "php"
      "composer"
      "blueutil"
      "pngpaste" # For telega
      "syncthing"
      "gnupg"
      "coreutils"
    ];
    casks = [
      "brave-browser"
      "slack"
      "spotify"
      "docker"
      "postman"
      "lastpass"
      "medis"
      "jetbrains-toolbox"
      "adoptopenjdk8"
      "keepassxc"
      "1password"
      "zoom"
    ];
    taps = [
      "AdoptOpenJDK/openjdk"
      "railwaycat/emacsmacport"
    ];
    extraConfig = ''
      brew "emacs-mac", args: ["with-imagemagick","with-native-compilation","with-modern-icon","with-xwidgets","with-librsvg"]
    '';
    onActivation = {
      cleanup = "zap";
    };
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixos/host/autoMac/default.nix
  environment.darwinConfig = "$HOME/.config/nixos/host/autoMac/default.nix";

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system = {
    stateVersion = 4;
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    defaults = {
      # Show hidden files in finder
      finder = {
        AppleShowAllFiles = true;
      };
      # Show hidden files, always
      NSGlobalDomain = {
        AppleShowAllFiles = true;
      };
    };
  };

  # NOTE: Raise max files per process https://gist.github.com/skylock/0117ec637d468f91260927b43b816eda
  launchd = {
    daemons = {
      "limit.maxfiles-extended" = {
        serviceConfig = {
          ProgramArguments = ["launchctl" "limit" "maxfiles" "64000" "524288"];
          RunAtLoad = true;
        };
      };
      "limit.maxproc-extended" = {
        serviceConfig = {
          ProgramArguments = ["launchctl" "limit" "maxproc" "2048" "2048"];
          RunAtLoad = true;
        };
      };
    };
  };

  services.lorri.enable = true;

  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql;
  #   dataDir = "${config.users.users.dlevy.home}/.cache/postgresql";
  # };

  services.redis = {
    enable = true;
    dataDir = "${config.users.users.dlevy.home}/.cache/redis";
    extraConfig = ''
      stop-writes-on-bgsave-error no
    '';
  };
}
