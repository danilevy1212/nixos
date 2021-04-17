{ config, lib, pkgs, environment, ... }:

{
  environment.systemPackages =
    [ (import ./nvidia-offload.nix { inherit pkgs; }).nvidia-offload ];
}
