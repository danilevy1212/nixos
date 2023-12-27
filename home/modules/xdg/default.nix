{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg = {
    enable = true;
    mimeApps = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      defaultApplications = {
        # Make brave default browser
        "x-scheme-handler/http" = ["brave-browser.desktop"];
        "x-scheme-handler/https" = ["brave-browser.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
      };
    };
  };

  # Make local executables visible
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
