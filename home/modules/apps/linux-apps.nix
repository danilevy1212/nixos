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
    teams

    # Browser for the...
    brave

    # Editing documents, normie style
    libreoffice

    # Keep my passwords safe
    keepassxc

    # I only use this to download Linux ISO images I super promise
    qbittorrent

    # video encoder
    handbrake

    # mpv + jellyfin, streaming heaven
    jellyfin-mpv-shim
  ];
}
