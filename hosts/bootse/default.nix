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
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = ["module_blacklist=i915" "nvidia_drm.fbdev=1"];

  # Enable networking
  networking.networkmanager.enable = true;

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

  environment.systemPackages = with pkgs; [
    # Monitor GPU usage
    nvtopPackages.full
  ];

  # NVIDIA crazyness
  services.xserver = {
    enable = true;
    videoDrivers = [
      "nvidia"
    ];
  };
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "535.129.03";
      sha256_64bit = "sha256-5tylYmomCMa7KgRs/LfBrzOLnpYafdkKwJu4oSb/AC4=";
      sha256_aarch64 = "sha256-i6jZYUV6JBvN+Rt21v4vNstHPIu9sC+2ZQpiLOLoWzM=";
      openSha256 = "sha256-/Hxod/LQ4CGZN1B1GRpgE/xgoYlkPpMh+n8L7tmxwjs=";
      settingsSha256 = "sha256-QKN/gLGlT+/hAdYKlkIjZTgvubzQTt4/ki5Y+2Zj3pk=";
      persistencedSha256 = "sha256-FRMqY5uAJzq3o+YdM2Mdjj8Df6/cuUUAnh52Ne4koME=";
      patches = with pkgs; let
        # https://forums.developer.nvidia.com/t/linux-6-7-3-545-29-06-550-40-07-error-modpost-gpl-incompatible-module-nvidia-ko-uses-gpl-only-symbol-rcu-read-lock/280908/19
        rcu_patch = fetchpatch {
          url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
          hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
        };
        # https://gist.github.com/joanbm/24f4d4f4ec69f0c37038a6cc9d132b43
        linux_6_8_patch = fetchpatch {
          url = "https://gist.github.com/joanbm/24f4d4f4ec69f0c37038a6cc9d132b43/raw/bacb9bf3617529d54cb9a57ae8dc9f29b41d4362/nvidia-470xx-fix-linux-6.8.patch";
          hash = "sha256-SPLC2uGdjHSy4h9i3YFjQ6se6OCdWYW6tlC0CtqmP50=";
          extraPrefix = "kernel/";
          stripLen = 1;
        };
      in [
        rcu_patch
        linux_6_8_patch
      ];
    };
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
    ];
  };
  virtualisation.docker.enableNvidia = true;

  # Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      vkd3d-proton
      vkd3d
      dxvk_2
      proton-ge-bin
      freetype
      openjdk21_headless
      wineWowPackages.waylandFull
    ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # AI
  services.ollama = {
    enable = true;
    acceleration = "cuda";
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
