# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  config,
  stable,
  unstable,
  ...
}: let
  gamescope-pkg = unstable.gamescope;
  gamescope-wsi-pkg = unstable.gamescope-wsi;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "module_blacklist=i915"
    "nvidia_drm.fbdev=1"
    # NOTE See https://forums.developer.nvidia.com/t/555-release-feedback-discussion/293652/32
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    # Monitor GPU usage
    nvtopPackages.full
    drm_info
    # Monitor FPS
    mangohud
    # Additional tools for Windows compatibility
    protontricks
    (lutris.override {
      extraPkgs = pkgs:
        with pkgs; [
          winetricks
          wineWowPackages.waylandFull
        ];
    })
    vulkan-loader
    gamescope-wsi-pkg
    # NOTE Temporary workaround, until gamescope-pkg add gamescopereaper in path
    gamescope-pkg
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

  # NVIDIA crazyness
  services.xserver = {
    enable = true;
    videoDrivers = [
      "nvidia"
    ];
  };
  hardware.nvidia = {
    modesetting.enable = true;
    # Fixes graphical glitches after suspend
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
    ];
    extraPackages32 = with pkgs; [
      pkgsi686Linux.vaapiVdpau
    ];
  };
  virtualisation.docker.enableNvidia = true;

  # Minimum requirements for Steam
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          gamescope-pkg
          gamescope-wsi-pkg
          vulkan-loader
          zenity
          wayland
        ];
    };
  };

  # Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
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
      vkd3d-proton
      vkd3d
      dxvk_2
      proton-ge-bin
      freetype
      openjdk21_headless
      wineWowPackages.waylandFull
      gamescope-wsi-pkg
      vulkan-loader
    ];
  };
  programs.gamescope = {
    enable = true;
    package = gamescope-pkg;
  };

  # Game-streaming
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
    # NOTE: This is a temporary workaround, fix hasn't made it to unstable yet. See https://github.com/NixOS/nixpkgs/issues/326299
    package = stable.sunshine;
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
