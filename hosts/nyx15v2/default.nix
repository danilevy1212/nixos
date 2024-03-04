# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  stable,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Select internationalization properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with stable.ibus-engines; [mozc];
    };
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = lib.mkDefault true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Screen control
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

  # GVFS (Connect to mobile devices)
  services.gvfs.enable = true;
}
