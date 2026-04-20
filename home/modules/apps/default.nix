{
  pkgs,
  config,
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
    home.sessionVariables = with pkgs; {
      BROWSER =
        if stdenv.isLinux
        then "firefox"
        else "chrome";
    };

    # Apps
    home.packages = with pkgs;
      [
        # Keep my passwords safe
        keepassxc
      ]
      ++ lib.optional cfg.isWork bitwarden-desktop
      ++ lib.optionals stdenv.isLinux [
        # Browser
        chromium
        # Pseudo-office
        libreoffice
        # raspi
        rpi-imager
        # I only use this to download Linux ISO images I super promise
        qbittorrent
        # Conferences
        zoom-us
        # Memorize
        anki
        # Proprietary musicality
        spotify
        # Social closeness
        telegram-desktop
      ];
  };
}
