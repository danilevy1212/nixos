{
  pkgs,
  config,
  unstable,
  stable,
  lib,
  ...
}: let
  cfg = config.userConfig;
in {
  # APPS that only run on the GUI
  config = lib.mkIf cfg.modules.gui.enable {
    # Video Player
    programs.mpv = {
      enable = true;
      config = {
        sub-auto = "exact";
        save-position-on-quit = true;
      };
    };

    # Nerdy PDF reader
    programs.zathura = {
      enable = true;
      options = {
        selection-clipboard = "clipboard";
      };
    };

    # Fork zathura when opening a new file
    home.shellAliases.zathura = "zathura --fork";

    # default browser
    home.sessionVariables = {BROWSER = "firefox";};

    # Apps
    home.packages = with pkgs; [
      # Proprietary musicality
      spotify

      # Social closeness
      telegram-desktop
      mattermost

      # Browser
      chromium

      # Keep my passwords safe
      keepassxc

      # I only use this to download Linux ISO images I super promise
      qbittorrent

      # Conferences
      zoom-us

      # Memorize
      anki

      # Pseudo-office
      libreoffice

      # raspi
      stable.rpi-imager
    ];
  };
}
