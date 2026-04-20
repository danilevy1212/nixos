{
  pkgs,
  stable,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.userConfig;
  # Force bruno to use X11 in linux
  brunoWrapped = pkgs.buildEnv {
    name = "bruno-wrapped";

    paths = [pkgs.bruno];

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

        # Sync with anything, anywhere, all at once
        mutagen

        # REST Client
        atac

        # e2e file transfer
        portal

        # Database client
        dbeaver-bin

        # Redis cli client
        redis
      ]
      ++ (
        if stdenv.isLinux
        then [brunoWrapped]
        else [bruno]
      );

    # File sharing, p2p style
    services.syncthing = with pkgs;
    # We get syncthing through brew on macos
      lib.mkIf stdenv.isLinux {
        enable = true;
        tray = {
          enable = true;
          command = "syncthingtray --wait";
        };
      };

    # Reuse an already-established connection when creating a new SSH session
    programs.ssh.extraConfig = ''
      ControlMaster auto
      ControlPath ~/.ssh/socket_%r@%h-%p
      ControlPersist 600
    '';

    ## Linux networking quirks
    # I 💙 bluetooth.
    services.blueman-applet.enable = stable.stdenv.isLinux;

    # Bluetooth remote control
    services.mpris-proxy.enable = stable.stdenv.isLinux;

    # I ❤ Internet
    services.network-manager-applet.enable = stable.stdenv.isLinux;
  };
}
