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
  openDrivers = true;
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
      vaapiIntel
      intel-media-driver
      vaapiVdpau
      vpl-gpu-rt
    ];
  };

  # Use discrete GPU to render the display
  hardware.nvidia = {
    open = openDrivers;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    modesetting.enable = true;
    powerManagement.enable = true;
    prime = {
      offload.enable = true;
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

  # Fast, compressed in-RAM swap to absorb spikes (preferred)
  zramSwap = {
    enable = true;
    # 3 GB
    memoryPercent = 10;
    # good ratio/speed balance
    algorithm = "zstd";
    # ensure zram is always used before disk swap
    priority = 100;
  };

  # Aggressive tuning to prevent swap usage except in emergencies
  boot.kernel.sysctl = {
    # Minimum value - only swap to prevent OOM kills (zram will still be preferred due to priority).
    "vm.swappiness" = 1;
    # Keep filesystem cache longer
    "vm.vfs_cache_pressure" = 50;
    # Start reclaiming memory earlier (reduces direct-reclaim stalls under pressure)
    "vm.watermark_scale_factor" = 200;
    # Keep 64MB free minimum (helps latency spikes under sudden allocations)
    "vm.min_free_kbytes" = 65536;
    # huge allocations that can’t be backed by RAM+swap are rejected up front instead of OOM-killing you later.
    "vm.overcommit_memory" = 2;
    # percent of RAM considered commit-eligible
    "vm.overcommit_ratio" = 90;
  };
}
