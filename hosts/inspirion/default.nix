# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../common
    ./../../common/linux
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    # NOTE https://discourse.nixos.org/t/getting-nvidia-to-work-avoiding-screen-tearing/10422/16
    kernelParams = [
      "nvidia-drm.modeset=1"
    ];
    # NOTE https://discourse.nixos.org/t/sound-not-working/12585
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=1
    '';
    hardware.enableAllFirmware = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # NOTE nvidia options taken from https://nixos.wiki/wiki/Nvidia#sync_mode
  services.xserver = {
    dpi = 144;
    # Enable touchpad support
    libinput.enable = true;
    # Enable external monitor through discrete GPU
    videoDrivers = ["nvidia"];
  };
  hardware.opengl.driSupport32Bit = true;

  # Always on GPU, unfortunately
  hardware.nvidia = {
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

  # Finger print scanner
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };

  # Main redis server
  services.redis.servers."apex-redis" = {
    enable = true;
    port = 6379;
  };
}
