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
    insomnia

    # Youtube Archiver
    yt-dlp

    # Database client, overkill mode
    (lib.mkIf (hostname == HOSTS.inspirion) jetbrains.datagrip)

    # A nice debugger with a terrible editor
    (lib.mkIf (hostname == HOSTS.inspirion) jetbrains.webstorm)

    # VPN Client for work
    (lib.mkIf (hostname == HOSTS.inspirion) openfortivpn)
  ];

  # default file-browser
  home.sessionVariables = {FILEMANAGER = "spacefm";};

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
