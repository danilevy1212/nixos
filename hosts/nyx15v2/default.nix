# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../common
    ./../../common/linux
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixosNyx15V2"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # High quality BT calls
  services.pipewire = {
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [{"device.name" = "~bluez_card.*";}];
        actions = {
          "update-props" = {
            "bluez5.auto-connect" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
          };
        };
      }
      {
        matches = [
          # Matches all sources
          {"node.name" = "~bluez_input.*";}
          # Matches all outputs
          {"node.name" = "~bluez_output.*";}
        ];
        actions = {
          "node.pause-on-idle" = false;
        };
      }
    ];
  };

  environment.systemPackages = lib.mkIf (config.services.xserver.enable) [
    (pkgs.writeShellScriptBin "x-dual" ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output eDP --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
            --output DisplayPort-0 --mode 1920x1080 --pos 0x0 --rotate normal \
            --output DisplayPort-1 --off
    '')
    (pkgs.writeShellScriptBin "x-solo" ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output eDP --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
            --output DisplayPort-0 --off \
            --output DisplayPort-1 --off
    '')
  ];

  # Enable blueman.
  services.blueman.enable = true;

  # Tell me the power!
  systemd.services.upower.enable = true;

  # Notify battery status
  services.upower.enable = true;
}
