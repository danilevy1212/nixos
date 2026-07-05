{
  pkgs,
  unstable,
  stable,
  ...
}: {
  # Core gaming stack shared across hosts (GPU-agnostic)
  # - Enables Steam with shared extra packages
  # - Enables Gamemode with a minimal sane setting
  # - Enables Gamescope (no session, no per-host args here)
  # - Installs common gaming tools and launchers
  # - Enables AntiMicroX for controller-as-mouse on the desktop
  #   (toggle a button combo to switch between mouse mode and gamepad passthrough)
  # - Improves peripheral compatibility (udev rules + uinput)

  # Gaming applications and helpers (GPU-agnostic)
  environment.systemPackages = with pkgs; [
    drm_info
    mangohud
    (stable.lutris.override {
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
    # Controller-as-mouse on the desktop (Steam Deck desktop mode-style)
    # Uses uinput so the cursor moves properly on Wayland (unlike Steam's SDL-based mouse emulation)
    antimicrox
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

  # Auto-launch AntiMicroX minimized to tray on login so controller-as-mouse
  # is always available. Configure Set 0 = mouse, Set 1 = empty (passthrough)
  # and assign a toggle button combo in the AntiMicroX GUI.
  # Uses last-saved profile; no hardcoded path so first run just opens clean.
  systemd.user.services.antimicrox = {
    description = "AntiMicroX gamepad-to-mouse mapper";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.antimicrox}/bin/antimicrox --tray --hidden";
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
