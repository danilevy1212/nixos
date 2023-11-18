{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./../../common
    ./../../common/macos
  ];

  services.nix-daemon.enable = true;
}
