{
  pkgs,
  config,
  stable,
  hostname,
  HOSTS,
  ...
}: let
  cfg = config.userConfig;
in {
  # Video Player
  programs.mpv = {
    enable = true;
    config = {
      sub-auto = "exact";
      save-position-on-quit = true;
    };
  };

  # Nerdy PDF reader
  programs.zathura = {enable = true;};

  # Fork zathura when opening a new file
  home.shellAliases.zathura = "zathura --fork";

  # default browser
  home.sessionVariables = {BROWSER = "brave";};

  # Apps
  home.packages = with pkgs;
    [
      # Proprietary musicality
      spotify

      # Social closeness
      tdesktop
      slack

      # Browser for the...
      brave

      # Keep my passwords safe
      keepassxc

      # I only use this to download Linux ISO images I super promise
      qbittorrent

      # Memorize
      anki
      cfg.obsidianmd

      # Pseudo-office
      stable.libreoffice

      # raspi
      stable.rpi-imager
    ]
    ++ (
      if hostname == HOSTS.nyx15v2
      then [unityhub]
      else []
    );
}
