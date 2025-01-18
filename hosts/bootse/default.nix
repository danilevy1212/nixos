# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  unstable,
  lib,
  config,
  ...
}: let
  gamescope-pkg = unstable.gamescope;
  gamescope-wsi-pkg = unstable.gamescope-wsi;
  openDrivers = false;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  # Only works with closed-source drivers
  boot.kernelParams =
    lib.optional (!openDrivers) "nvidia.NVreg_EnableGpuFirmware=0";
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod;

  # Prevent system from waking up on PCI devices, except for  ethernet
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    # Enable wakeup for the network card
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="06:00.0", ATTR{power/wakeup}="enabled"
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    # Monitor GPU usage
    nvtopPackages.full
    drm_info
    # Monitor FPS
    mangohud
    # Additional tools for Windows compatibility
    (lutris.override {
      extraPkgs = pkgs:
        with pkgs; [
          winetricks
          wineWowPackages.waylandFull
        ];
    })
    vulkan-loader
    gamescope-wsi-pkg
  ];

  # Performance boost
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        inhibit_screensaver = true;
      };
    };
  };

  # Last time I buy an Intel CPU.
  # See https://www.reddit.com/r/hardware/comments/1e9mmxg/update_on_intel_k_sku_instability_from_intel/
  hardware.cpu.intel.updateMicrocode = true;

  # NVIDIA crazyness
  services.xserver = {
    enable = true;
    videoDrivers = [
      "nvidia"
    ];
  };
  hardware.nvidia = {
    open = openDrivers;
    #   NOTE  See if the new stable version works fine
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    modesetting.enable = true;
    # Fixes graphical glitches after suspend
    powerManagement.enable = true;
    nvidiaSettings = true;
    # Allow Intel graphics for video encoding
    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
      nvidia-vaapi-driver
      vaapiVdpau
    ];
    extraPackages32 = with pkgs; [
      pkgsi686Linux.vaapiVdpau
      pkgsi686Linux.intel-media-driver
    ];
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Minimum requirements for Steam
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          gamescope-pkg
          gamescope-wsi-pkg
          vulkan-loader
        ];
    };
  };

  # Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
    gamescopeSession = {
      enable = true;
      args = [
        "-w"
        "3840"
        "-h"
        "2160"
        "-r"
        "144"
        "--hdr-enabled"
        "--hdr-debug-force-output"
        "--hdr-sdr-content-nits"
        "630"
      ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
  programs.gamescope = {
    enable = true;
    package = gamescope-pkg;
    capSysNice = true;
  };

  # Game-streaming
  services.sunshine = {
    enable = true;
    # Enable nvenc support
    package = with pkgs;
      (pkgs.sunshine.override {
        cudaSupport = true;
        cudaPackages = cudaPackages;
      })
      .overrideAttrs (old: {
        nativeBuildInputs =
          old.nativeBuildInputs
          ++ [
            cudaPackages.cuda_nvcc
            (lib.getDev cudaPackages.cuda_cudart)
          ];
        cmakeFlags =
          old.cmakeFlags
          ++ [
            "-DCMAKE_CUDA_COMPILER=${(lib.getExe cudaPackages.cuda_nvcc)}"
          ];
      });
    openFirewall = true;
    capSysAdmin = true;
  };

  environment.variables = {
    # Make sure all HW decoding uses the nvidia
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "nvidia";
    # Allow HDR with nvidia GPU
    KWIN_DRM_ALLOW_NVIDIA_COLORSPACE = 1;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Better compatibility with peripherals
  services.udev.packages = [pkgs.game-devices-udev-rules];
  hardware.uinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dlevym = {
    isNormalUser = true;
    description = "Daniel Levy Moreno";
    extraGroups = ["networkmanager" "wheel"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
