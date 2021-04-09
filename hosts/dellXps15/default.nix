# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    <home-manager/nixos> # Home Manager integration.
  ];

  nix = {
    trustedUsers = [ "root" "dlevym" ];
    nixPath = [
      "nixos-config=/etc/nixos/hosts/dellXps15/default.nix"
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    gc = { automatic = true; };
  };

  # Sorry, Stallman-chan
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # NixOS uses NTFS-3G for NTFS support.
  boot.supportedFilesystems = [ "ntfs" ];

  # Cutting-edgyness
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

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

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };
  };

  console = {
    font = "Lat2-Terminus16";
    earlySetup = true;
    useXkbConfig = true;
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Enable sound.
  sound = { enable = true; };

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull; # PulseAudio with bluetooth support
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    configFile = pkgs.writeText "default.pa" ''
      load-module module-bluetooth-policy
      load-module module-bluetooth-discover
      ## module fails to load with
      ##   module-bluez5-device.c: Failed to get device path from module arguments
      ##   module.c: Failed to load module "module-bluez5-device" (argument: ""): initialization failed.
      # load-module module-bluez5-device
      # load-module module-bluez5-discover
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dlevym = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager" # Can use network-manager
    ];
  };

  # My user environment.
  home-manager = {
    useGlobalPkgs =
      true; # Home manager has access to system level dependencies.
    useUserPackages = true; # Unclutter $HOME.
    users.dlevym = (import ./../../home/home.nix);
  };

  # Default shell.
  programs.zsh.enable = true;
  users.extraUsers.dlevym = { shell = pkgs.zsh; };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # These are the defaults, and xdg.enable does set them, but due to load
  # order, they're not set before environment.variables are set, which could
  # cause race conditions.
  environment = {
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";

      # IBUS
      GTK_IM_MODULE = "ibus";
      QT_IM_MODULE = "ibus";
      XMODIFIERS = "@im=ibus";
      XMODIFIER = "@im=ibus";
    };
    # List packages installed in system profile. To search, run:
    # $ nix search ...
    systemPackages = with pkgs;
      [ wget vim utillinux pciutils lxappearance htop ]
      ++ (with pkgs.unixtools; [ netstat ifconfig ]) ++ [
        (import ./../../pkgs/nvidia-offload.nix {
          inherit pkgs;
        }).nvidia-offload
      ];
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

  # Let me lock the screen. $ TODO Find alternatives.
  programs.slock.enable = true;

  # Documentation, documentation, documentation!
  documentation.man = {
    enable = true;
    generateCaches = true;
  };

  # List services that you want to enable:

  # Backlight control
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      {
        keys = [ 224 ];
        events = [ "key" ];
        command = "/run/current-system/sw/bin/light -U 5";
      }
      {
        keys = [ 225 ];
        events = [ "key" ];
        command = "/run/current-system/sw/bin/light -A 5";
      }
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    layout = "us(altgr-intl)";
    xkbOptions = "ctrl:nocaps";
    autoRepeatInterval = 25;
    autoRepeatDelay = 200;
    libinput = {
      enable = true; # Enable touchpad support
      touchpad = { disableWhileTyping = true; };
    };
    desktopManager = {
      session = [{
        name = "home-manager";
        start = ''
          ${pkgs.stdenv.shell} $HOME/.xsession-hm &
          waitPID=$!
          # TODO Make it a explicit systemd file, at user level!
          /run/current-system/sw/bin/ibus-daemon -d -x
          exec $HOME/.local/bin/xmonad
        '';
      }];
    };
    displayManager = {
      lightdm.greeters = {
        gtk = with pkgs; {
          enable = true;
          iconTheme = {
            name = "Papirus-Dark";
            package = papirus-icon-theme;
          };
          theme = {
            name = "Nordic";
            package = nordic;
          };
          cursorTheme = {
            name = "Numix-Cursor";
            package = numix-cursor-theme;
          };
        };
      };
    };
    videoDrivers = [ "nvidia" ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable blueman.
  services.blueman.enable = true;

  # Tell me the power!
  systemd.services.upower.enable = true;

  # So I can change gtk-themes from home-manager.
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  # Key-Values and pears?
  services.redis.enable = true;

  # Documents, DOCUMENTS, DOCUMENTS!
  services.mongodb = { enable = true; };

  # Notify battery status
  services.upower.enable = true;

  # Don't bother me for passwords.
  security.polkit.enable = true;

  # Make daily automatic upgrades.
  system.autoUpgrade.enable = true;

  # The just in case desktop
  # services.xserver.desktopManager.plasma5.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "21.03"; # Did you read the comment?
}
