{
  pkgs,
  unstable,
  lib,
  ...
}: {
  # Core gaming stack shared across hosts (GPU-agnostic)
  # - Enables Steam with shared extra packages
  # - Enables Gamemode with a minimal sane setting
  # - Enables Gamescope (no session, no per-host args here)
  # - Installs common gaming tools and launchers
  # - Improves peripheral compatibility (udev rules + uinput)

  # Minimum requirements for Steam and common extras
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          unstable.gamescope
          unstable.gamescope-wsi
          vulkan-loader
        ];
    };
  };

  # Gaming applications and helpers (GPU-agnostic)
  environment.systemPackages = with pkgs; [
    drm_info
    mangohud
    (lutris.override {
      extraPkgs = pkgs:
        with pkgs; [
          winetricks
          wineWowPackages.waylandFull
        ];
    })
    vulkan-loader
    unstable.gamescope-wsi
    (heroic.override {
      extraPkgs = pkgs: [
        unstable.gamescope
        unstable.gamescope-wsi
        gamemode
      ];
    })
  ];

  # Gamemode on with a small, safe tweak
  programs.gamemode = {
    enable = true;
    settings.general = {inhibit_screensaver = true;};
  };

  # Basic gamescope enable (no session)
  programs.gamescope = {
    enable = true;
    package = unstable.gamescope;
    capSysNice = true;
  };

  # Steam (no gamescope session here)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  # Better compatibility with peripherals
  services.udev.packages = [pkgs.game-devices-udev-rules];
  hardware.uinput.enable = true;
}
