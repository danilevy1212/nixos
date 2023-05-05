{
  config,
  lib,
  pkgs,
  unstable,
  hostname,
  HOSTS,
  ...
}: {
  home.packages = with pkgs; [
    # File management.
    spaceFM

    # REST Client
    (insomnia.overrideAttrs
      # NOTE  https://github.com/NixOS/nixpkgs/pull/227905
      (finalAttrs: previousAttrs: {
        preFixup = ''
          wrapProgram "$out/bin/insomnia" "''${gappsWrapperArgs[@]}" --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [curl glibc libudev0-shim nghttp2 openssl stdenv.cc.cc.lib]}
        '';
      }))

    # Youtube Archiver
    yt-dlp

    # Database client, overkill mode
    (lib.mkIf (hostname == HOSTS.inspirion) jetbrains.datagrip)
  ];

  # default file-browser
  home.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {FILEMANAGER = "spacefm";};

  # Reuse an already-established connection when creating a new SSH session
  programs.ssh.extraConfig = ''
    ControlMaster auto
    ControlPath ~/.ssh/socket_%r@%h-%p
    ControlPersist 600
  '';

  imports = [
    ./linux-services.nix
  ];
}
