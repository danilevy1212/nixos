{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # Proprietary musicality
    spotify

    # Non-proprietary musicality
    (import ./nuclear.nix pkgs)

    # Social closeness
    ferdi
    tdesktop
    slack

    # Browser for the...
    brave

    # video player
    mpv-with-scripts

    # Editing documents, normie style
    libreoffice
  ];

  # default browser
  home.sessionVariables = { BROWSER = "brave"; };

  # Make brave default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
    };
  };
}
