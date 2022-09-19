{config, ...}: {
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Make brave default browser
        "x-scheme-handler/http" = ["brave-browser.desktop"];
        "x-scheme-handler/https" = ["brave-browser.desktop"];
      };
    };
  };

  # Make local executables visible
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
