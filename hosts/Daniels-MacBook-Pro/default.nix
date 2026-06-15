{
  pkgs,
  userConfig,
  ...
}: {
  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # Homebrew Integration
  homebrew = {
    enable = true;
    # Uninstalls anything not listed here
    onActivation.cleanup = "zap";
    taps = [];
    brews = [
      "mas"
      "docker-completion"
    ];
    casks = ["syncthing-app" "bitwarden"];
  };

  # Generate brew shellenv at activation time
  system.activationScripts.postActivation.text = ''
    if [[ -x /opt/homebrew/bin/brew ]]; then
      /opt/homebrew/bin/brew shellenv > /etc/brew-shellenv.sh
    fi
  '';
  # Make sure cli session load it up
  programs.zsh.loginShellInit = ''
    if [[ -f /etc/brew-shellenv.sh ]]; then
      source /etc/brew-shellenv.sh
    fi
  '';

  # Point darwin-rebuild at our flake so we don't need --flake <path>
  environment.etc."nix-darwin/flake.nix".source = "/Users/${userConfig.username}/.config/nix-darwin/flake.nix";

  environment.systemPackages = with pkgs; [
    # main editor
    neovim

    # Use gnu utils and not the freebsd ones
    coreutils-full
    gnugrep
    gnused
    gnutar
    findutils
  ];

  # Define the user so Home Manager knows where the home directory is
  users.users."${userConfig.username}" = {
    name = userConfig.username;
    home = "/Users/${userConfig.username}";
  };

  # macOS System Defaults
  system.primaryUser = userConfig.username;
  system.defaults = {
    dock = {
      autohide = true;
      # Don't rearrange Spaces based on use
      mru-spaces = false;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmb"; # Column view
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Dark mode
      KeyRepeat = 2;
    };
    # Disable 'Select the previous input source' (Ctrl+Space) so we can use
    # it in the terminal (e.g. telescope.nvim's to_fuzzy_refine binding)
    CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys."60" = {
        enabled = false;
      };
    };
  };

  # Use sudo with touchID
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
  };
}
