# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  userConfig,
  pkgs,
  lib,
  ...
}: let
  openDrivers = false;
in {
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
    kernelParams = lib.optional (!openDrivers) "nvidia.NVreg_EnableGpuFirmware=0";
    kernelPackages = lib.mkForce pkgs.linuxPackages;
  };

  # Touchpad settings
  services.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
    };
  };

  # NOTE nvidia options taken from https://nixos.wiki/wiki/Nvidia#sync_mode
  services.xserver = {
    dpi = 144;
    # Enable external monitor through discrete GPU
    videoDrivers = [
      "nvidia"
    ];
  };
  # Enable opengl support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      vpl-gpu-rt
    ];
  };
  # Make sure all HW decoding uses the intel video
  environment.sessionVariables = {
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "i915";
  };

  # Use discrete GPU to render the display
  hardware.nvidia = {
    open = openDrivers;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    modesetting.enable = true;
    powerManagement.enable = true;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # 1password and its GUI
  programs._1password = {
    enable = true;
  };
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [userConfig.username];
  };

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # Tell me the power!
  systemd.services.upower.enable = true;

  # Notify battery status
  services.upower.enable = true;
}
