{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    # Proprietary musicality
    spotify

    # Non-proprietary musicality
    (import ./nuclear.nix pkgs)

    # Social closeness
    tdesktop
    slack

    # Browser for the...
    brave

    # Editing documents, normie style
    libreoffice

    # Keep my passwords safe
    keepassxc

    # I only use this to download Linux ISO images I super promise
    qbittorrent
  ];

  # Make brave default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = ["brave-browser.desktop"];
      "x-scheme-handler/https" = ["brave-browser.desktop"];
    };
  };
}
