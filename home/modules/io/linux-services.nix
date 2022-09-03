{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  # Connect up to external devices.
  services.udiskie.enable = true;

  # I 💙 bluetooth.
  services.blueman-applet.enable = true;

  # Bluetooth remote control
  services.mpris-proxy.enable = true;

  # I ❤ Internet
  services.network-manager-applet.enable = true;
}
