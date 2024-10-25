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
    home.sessionVariables = {BROWSER = "brave";};

    # Apps
    home.packages = with pkgs; [
      # Proprietary musicality
      spotify

      # Social closeness
      tdesktop
      slack

      # Browser for the...
      stable.brave

      # Keep my passwords safe
      keepassxc

      # I only use this to download Linux ISO images I super promise
      qbittorrent

      # Conferences
      zoom-us

      # Memorize
      stable.anki
      unstable.obsidian

      # Pseudo-office
      stable.libreoffice

      # raspi
      stable.rpi-imager
    ];

    # 🤮 I hate this, but everyone else in the team uses it, so I need to make sure what works for me works for them.
    programs.vscode = lib.mkIf cfg.work {
      enable = true;
    };
  };
}
