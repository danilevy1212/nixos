{config, ...}: {
  xdg = {enable = true;};

  # Make local executables visible
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
