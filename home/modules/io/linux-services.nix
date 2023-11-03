{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  # I 💙 bluetooth.
  services.blueman-applet.enable = true;

  # Bluetooth remote control
  services.mpris-proxy.enable = true;

  # I ❤ Internet
  services.network-manager-applet.enable = true;
}
