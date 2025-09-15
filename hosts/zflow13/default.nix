{pkgs, ...}: let
  # From https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551
  folioReset = pkgs.writeShellScript "asus-folio-reset.sh" ''
    # Reload ASUS HID
    ${pkgs.kmod}/bin/modprobe -r hid_asus
    ${pkgs.kmod}/bin/modprobe hid_asus
    # Restore keyboard backlight
    [ -e /sys/class/leds/asus::kbd_backlight/brightness ] && echo 3 > /sys/class/leds/asus::kbd_backlight/brightness
  '';
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # avoids some EC/HID flakiness later
  boot.kernelParams = ["mem_sleep_default=deep"];

  # ASUS HID quirks (touchpad/extra keys)
  boot.initrd.kernelModules = ["hid_asus"];
  boot.kernelModules = [
    "hid_asus"
  ];
  # Enable ASUS touchpad functionality
  boot.extraModprobeConfig = ''
    options hid_asus enable_touchpad=1
  '';

  # Run once at boot
  systemd.services."asus-folio-reset" = {
    description = "ROG Flow Z13 folio HID reset (boot)";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = folioReset;
    };
  };

  # Turn on backlight on resume
  systemd.services."asus-folio-reset-resume" = {
    description = "ROG Flow Z13 folio HID reset after resume";
    wantedBy = ["sleep.target"];
    after = ["sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = folioReset;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support
  services.libinput.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # for `libinput list-devices`
    libinput
  ];

  # See https://asus-linux.org/guides/nixos/
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
}
