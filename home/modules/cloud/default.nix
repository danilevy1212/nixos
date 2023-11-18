{
  config,
  lib,
  pkgs,
  ...
}: {
  # File sharing, p2p style
  services.syncthing = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };

  # Work stuff
  home.packages = with pkgs; [
    awscli2
    rclone
  ];

  home.sessionVariables = {
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    AWS_PROFILE = "autopay-developer";
  };
}
