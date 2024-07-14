{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia-offload
    ./xrandr-utils
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behavior.
  networking = {
    interfaces = {wlp59s0.useDHCP = true;};
  };

  # PulseAudio with bluetooth support
  hardware.pulseaudio = lib.mkIf config.hardware.pulseaudio.enable {
    package = pkgs.pulseaudioFull;
    # Auto switching audio on connect.
    extraConfig = "load-module module-switch-on-connect";
  };

  # Protect the RAM
  nix.buildCores = 4;

  # Video Playing acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
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
