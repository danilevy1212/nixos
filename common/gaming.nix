{
  pkgs,
  unstable,
  userConfig,
  ...
}: {
  # Core gaming stack shared across hosts (GPU-agnostic)
  # - Enables Steam with shared extra packages
  # - Enables Gamemode with a minimal sane setting
  # - Enables Gamescope (no session, no per-host args here)
  # - Installs common gaming tools and launchers
  # - Runs sc-controller for Steam Controller trackpad-as-mouse on the desktop
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
    # Steam Controller (2026) user-mode driver; maps the trackpads to a uinput mouse
    sc-controller
  ];

  # gamemoded changes the CPU governor through polkit; the rule only allows the gamemode group
  users.users.${userConfig.username}.extraGroups = ["gamemode"];

  # Gamemode on with a small, safe tweak
  programs.gamemode = {
    enable = true;
    # gamemode.ini takes 0/1; a boolean renders as "true" and is rejected
    settings.general = {inhibit_screensaver = 1;};
  };

  # Basic gamescope enable (no session)
  programs.gamescope = {
    enable = true;
    package = unstable.gamescope;
    # Until https://github.com/NixOS/nixpkgs/issues/523427 is fixed
    capSysNice = false;
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
          # Controller support
          hidapi
        ];
    };
  };

  # Better compatibility with peripherals
  services.udev.packages = [pkgs.game-devices-udev-rules];

  # 8BitDo Pro 2 D-Input hidraw rules
  # - game-devices-udev-rules (above) already covers:
  #     • evdev/input nodes for X-Input and D-Input modes (8bitdo-gdu.rules)
  #     • uinput access via uaccess tag (uinput-dev-early-creation.rules)
  # - it has NO hidraw rules, so these are needed for gyro + back paddles
  #   (P1/P2) when the Pro 2 is in D-Input mode (vendor 2dc8, product 6006)
  # - ACTION!="remove" required for systemd >=258 (uaccess must apply on "change" too)
  # See: https://github.com/ValveSoftware/steam-devices/issues/64
  services.udev.extraRules = ''
    # 8BitDo Pro 2 D-Input — USB / 2.4GHz dongle
    ACTION!="remove", KERNEL=="hidraw*", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="6006", MODE="0660", TAG+="uaccess"

    # 8BitDo Pro 2 D-Input — Bluetooth (IDs appear uppercase in sysfs KERNELS)
    ACTION!="remove", KERNEL=="hidraw*", KERNELS=="*2DC8:6006*", MODE="0660", TAG+="uaccess"
  '';

  hardware.uinput.enable = true;

  # sc-controller daemon. Device access comes from Steam's udev rules
  # (programs.steam) and hardware.uinput. Pick a profile once in the sc-controller GUI.
  systemd.user.services.scc-daemon = {
    description = "sc-controller Steam Controller driver";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sc-controller}/bin/scc-daemon start --foreground";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
