{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: {
  home.packages = with pkgs; [
    # File management.
    (lib.mkIf stdenv.isLinux spaceFM)

    # DB Client
    dbeaver

    # REST Client
    (lib.mkIf pkgs.stdenv.isLinux unstable.postman)

    # Youtube Archiver
    yt-dlp
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
