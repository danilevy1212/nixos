{
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    ../../common/home-manager.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
  ];

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  # default shell on catalina
  programs.zsh.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # --- Homebrew Integration ---
  homebrew = {
    enable = true;
    # Uninstalls anything not listed here
    onActivation.cleanup = "zap";
    taps = [];
    brews = ["mas"];
    casks = ["syncthing-app"];
  };

  # Define the user so Home Manager knows where the home directory is
  users.users."${userConfig.username}" = {
    name = userConfig.username;
    home = "/Users/${userConfig.username}";
  };

  # --- macOS System Defaults ---
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
  };
}
