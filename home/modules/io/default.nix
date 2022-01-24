{ config, lib, pkgs, unstable, ... }:

{
  home.packages = with pkgs; [
    # File management.
    spaceFM

    # DB Client
    mongodb-tools
    mongodb-compass
    unstable.dbeaver

    # Key-Values galore
    redis

    # REST Client
    unstable.postman
  ];

  # default file-browser
  home.sessionVariables = { FILEMANAGER = "spacefm"; };

  # Connect up to external devices.
  services.udiskie.enable = true;

  # I 💙 bluetooth.
  services.blueman-applet.enable = true;

  # I ❤ Internet
  services.network-manager-applet.enable = true;
}
