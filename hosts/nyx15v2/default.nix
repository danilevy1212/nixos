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

  # Select internationalization properties.
  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    extraLocaleSettings = {
      LC_CTYPE = "en_US.UTF-8";
      LC_COLLATE = "en_US.UTF-8";
    };
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [mozc];
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
}
