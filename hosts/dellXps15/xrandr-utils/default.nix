{ pkgs, ... }: {
  environment.systemPackages = with (import ./xcreen.nix { inherit pkgs; }); [
    horizontal
    solo
  ];
}
