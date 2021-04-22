{ config, lib, pkgs, ... }: {
  # TODO I shall replace you with rclone and gdrive soon!
  services.dropbox = {
    enable = true;
    path = "${config.home.homeDirectory}/Cloud";
  };

  home.packages = with pkgs; [
    aws
  ];
}
