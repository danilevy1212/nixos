{
  pkgs,
  stable,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.userConfig;
in {
  config = {
    home.packages = with pkgs;
      [
        # Mount anything, anywhere, all at once
        rclone

        # REST Client
        insomnia
        bruno

        # Database client
        dbeaver
      ]
      ++ lib.optionals cfg.work [
        # Work stuff
        stable.awscli2
      ];

    # File sharing, p2p style
    services.syncthing = {
      enable = true;
      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };

    home.sessionVariables = mkIf cfg.work {
      AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
      AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
      AWS_PROFILE = "autopay-developer";
    };

    # Reuse an already-established connection when creating a new SSH session
    programs.ssh.extraConfig = ''
      ControlMaster auto
      ControlPath ~/.ssh/socket_%r@%h-%p
      ControlPersist 600
    '';

    # I 💙 bluetooth.
    services.blueman-applet.enable = true;

    # Bluetooth remote control
    services.mpris-proxy.enable = true;

    # I ❤ Internet
    services.network-manager-applet.enable = true;
  };
}
