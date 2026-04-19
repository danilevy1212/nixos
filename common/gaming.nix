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

  # Gaming applications and helpers (GPU-agnostic)
  environment.systemPackages = with pkgs; [
    drm_info
    mangohud
    (lutris.override {
      extraPkgs = pkgs:
        with pkgs; [
          winetricks
          wineWow64Packages.waylandFull
          freetype
          pkgsi686Linux.freetype
          fontconfig
          pkgsi686Linux.fontconfig
        ];
    })
    vulkan-loader
    unstable.gamescope-wsi
    (heroic.override {
      extraPkgs = pkgs: [
        unstable.gamescope
        unstable.gamescope-wsi
        gamemode
        freetype
        pkgsi686Linux.freetype
        fontconfig
        pkgsi686Linux.fontconfig
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

    # Use the native module option to inject extra packages into the Steam FHS
    package = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          unstable.gamescope
          unstable.gamescope-wsi
          vulkan-loader
          # Ensure Steam and Proton can see FreeType libraries
          freetype
          fontconfig
          pkgsi686Linux.freetype
          pkgsi686Linux.fontconfig
        ];
    };
  };

  # Better compatibility with peripherals
  services.udev.packages = [pkgs.game-devices-udev-rules];
  hardware.uinput.enable = true;
}
