{
  pkgs,
  stable,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.userConfig;
  # NOTE Force bruno to use X11
  brunoWrapped = pkgs.buildEnv {
    name = "bruno-wrapped";

    paths = [stable.bruno];

    buildInputs = [pkgs.makeWrapper];

    postBuild = ''
      wrapProgram $out/bin/bruno \
        --prefix PATH : ${pkgs.coreutils}/bin \
        --unset "WAYLAND_DISPLAY"
    '';

    pathsToLink = ["/bin" "/share"];
  };
in {
  config = {
    home.packages = with pkgs;
      [
        # Mount anything, anywhere, all at once
        rclone

        # REST Client
        brunoWrapped
        atac

        # e2e file transfer
        portal

        # Database client
        stable.dbeaver-bin

        # Redis cli client
        redis
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
        package = stable.syncthingtray;
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
