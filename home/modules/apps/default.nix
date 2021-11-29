{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # TODO Look into mopidy instead
    # Proprietary musicality
    spotify

    # Social closeness
    ferdi

    # Browser for the...
    brave

    # A browser for vimmers
    vieb

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
    associations.added = {
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
    };
  };
}
