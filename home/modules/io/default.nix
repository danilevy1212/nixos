{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # File management.
    spaceFM

    # DB Client
    mongodb-tools
    mongodb-compass

    # Key-Values galore
    redis
    redis-desktop-manager

    # REST Client
    postman
  ];

  # Connect up to external devices.
  services.udiskie.enable = true;

  # I 💙 bluetooth.
  services.blueman-applet.enable = true;

  # I ❤ Internet
  services.network-manager-applet.enable = true;
}
