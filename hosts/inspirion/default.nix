# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  config,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  };

  # NOTE nvidia options taken from https://nixos.wiki/wiki/Nvidia#sync_mode
  services.xserver = {
    dpi = 144;
    # Enable touchpad support
    libinput.enable = true;
    # Enable external monitor through discrete GPU
    videoDrivers = [
      "nvidia"
    ];
  };
  # Enable opengl support
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Use discrete GPU to render the display
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
    };
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    _1password-gui
  ];

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # Tell me the power!
  systemd.services.upower.enable = true;

  # Notify battery status
  services.upower.enable = true;

  # Main redis server
  services.redis.servers."apex-redis" = {
    enable = true;
    port = 6379;
  };
}
