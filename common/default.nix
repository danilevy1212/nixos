{
  config,
  lib,
  pkgs,
  unstable,
  emacs-overlay,
  ...
}: {
  nixpkgs.overlays = [emacs-overlay];

  # Set your time zone.
  time.timeZone = "America/New_York";

  nix = {
    gc = {automatic = true;};
    package = pkgs.nixFlakes;
    # Protect nix-shell against garbage collection
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    config = {
      # Sorry, Stallman-chan
      allowUnfree = true;
      # Allow unsopported as long as they are not broken
      allowUnsupportedSystem = true;
    };
  };

  # My user environment.
  home-manager = {
    # Home manager has access to system level dependencies.
    useGlobalPkgs = true;
    # Unclutter $HOME.
    useUserPackages = true;
    extraSpecialArgs = {inherit unstable;};
  };

  environment = {
    variables = {
      # !https://github.com/NixOS/nixpkgs/issues/16327
      NO_AT_BRIDGE = "1";

      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which could
      # cause race conditions.
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";

      # IBUS
      GTK_IM_MODULE = "ibus";
      QT_IM_MODULE = "ibus";
      XMODIFIERS = "@im=ibus";
      XMODIFIER = "@im=ibus";
    };
    # Just as good.
    shellAliases = {vim = "nvim";};
    # List packages installed in system profile. To search, run:
    # $ nix search ...
    systemPackages = with pkgs;
      [
        gitAndTools.gitFull
        neovim
        wget
        tree
        htop
        docker-compose
        utillinux
        openvpn
        (import ./../pkgs/colortest {inherit pkgs;})
      ]
      ++ (with pkgs.unixtools; [netstat ifconfig]) # Basic network
      ++ [nix-prefetch-git cachix nix-tree]; # Nix convinience
  };

  # Default shell
  programs.zsh = {enable = true;};

  # Minimal bash config (for root)
  # autocd
  programs.bash.interactiveShellInit = "shopt -s autocd";
}
