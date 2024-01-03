{
  pkgs,
  stable,
  ...
}: {
  # File sharing, p2p style
  services.syncthing = {
    enable = true;
    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };

  # Work stuff
  home.packages = with pkgs; [
    stable.awscli2
    rclone
  ];

  home.sessionVariables = {
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    AWS_PROFILE = "autopay-developer";
  };
}
