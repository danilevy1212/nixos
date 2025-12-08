{
  pkgs,
  lib,
  stable,
  config,
  userConfig,
  ...
}: let
  openDrivers = true;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../common/sunshine.nix
    ../../common/gaming.nix
    ../../common/ollama.nix
  ];
  # Only works with closed-source drivers
  boot.kernelParams =
    (lib.optional (!openDrivers) "nvidia.NVreg_EnableGpuFirmware=0")
    ++ [
      "pci=nomsi"
      "pcie_aspm=off"
    ];

  # Prevent system from waking up on PCI devices, except for  ethernet
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    # Enable wakeup for the network card
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="06:00.0", ATTR{power/wakeup}="enabled"
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

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
      libva-vdpau-driver
    ];
    extraPackages32 = with pkgs; [
      pkgsi686Linux.libva-vdpau-driver
      pkgsi686Linux.intel-media-driver
    ];
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Bootse-specific package overrides
  nixpkgs.config.packageOverrides = pkgs: {
    # Disable CUDA support for ueberzugpp to avoid build issues
    ueberzugpp = pkgs.ueberzugpp.override {enableOpencv = false;};
  };

  # Default browser
  programs.firefox = {
    # NOTE  Pinning stable, see https://github.com/NixOS/nixpkgs/issues/457406
    package = stable.firefox;
  };

  # Gamescope session for posterity
  programs.steam.gamescopeSession = {
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

  # Enable CUDA support for sunshine (imported from common/sunshine.nix)
  nixpkgs.config.cudaSupport = true;

  environment.variables = {
    # Prefer NVIDIA drivers for decoding
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "nvidia";
    # Allow HDR with NVIDIA GPU
    KWIN_DRM_ALLOW_NVIDIA_COLORSPACE = 1;
    # To be able to use kscreen-doctor from SSH
    XDG_SESSION_TYPE = "wayland";
    XDG_RUNTIME_DIR = "/run/user/$(id -u)";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
    QT_QPA_PLATFORM = "wayland";
  };
  # GPU Watch
  environment.systemPackages = [
    stable.nvtopPackages.nvidia
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:
  hardware.bluetooth.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
  ];

  # Auto-login
  services.displayManager.autoLogin = {
    enable = true;
    user = userConfig.username;
  };

  # Kill hanging processes after 3 mins
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "90s";
  };

  # High-memory system overrides
  zramSwap.memoryPercent = lib.mkForce 5; # 5% is more reasonable for 128GB system
  boot.kernel.sysctl."vm.min_free_kbytes" = lib.mkForce 131072; # 128MB for high-memory system
}
