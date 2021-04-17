{ config, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./../../common
    ./../../pkgs/nvidia-offload
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behavior.
  networking = {
    useDHCP = false;
    hostName = "nixosXps15"; # Define your hostname.
    interfaces = { wlp59s0.useDHCP = true; };
    # Port's for work stuff.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9007 ];
    };
    # Give me those sweet interwebs
    networkmanager = { enable = true; };
  };

  # Video Playing acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Nvidia offload
  hardware.nvidia.prime = {
    offload.enable = true;

    # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
    intelBusId = "PCI:0:2:0";

    # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
    nvidiaBusId = "PCI:1:0:0";
  };

  # Configure keymap in X11
  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Enable blueman.
  services.blueman.enable = true;

  # Tell me the power!
  systemd.services.upower.enable = true;

  # Notify battery status
  services.upower.enable = true;
}
