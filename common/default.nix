{ config, lib, pkgs, ... }:

{
  imports = [
    <home-manager/nixos> # Home Manager integration.
    ./../cachix.nix
  ];

  # Common NIX_PATH
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    }))
  ];

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  nix = {
    trustedUsers = [ "root" "dlevym" ];
    gc = { automatic = true; };
    # Protect nix-shell against garbage collection
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Sorry, Stallman-chan
  nixpkgs.config.allowUnfree = true;

  boot = {
    # NixOS uses NTFS-3G for NTFS support.
    supportedFilesystems = [ "ntfs" ];

    # Cutting-edgyness
    kernelPackages = pkgs.linuxPackages;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ mozc ];
    };
  };

  # Less eye-sore console font.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Enable sound.
  sound = { enable = true; };
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull; # PulseAudio with bluetooth support
  };

  # Explicit PulseAudio support in applications
  nixpkgs.config.pulseaudio = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dlevym = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager" # Can use network-manager
      "audio" # Pulse Audio
      "docker" # Docker
    ];
  };

  # My user environment.
  home-manager = {
    useGlobalPkgs =
      true; # Home manager has access to system level dependencies.
    useUserPackages = true; # Unclutter $HOME.
    users.dlevym = (import ./../home/home.nix);
  };

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

      # EDITOR TODO Change to `emacs` when theme problems are solved.
      EDITOR = "nvim";

      # Mongo Memory Server HACK
      MONGOMS_SYSTEM_BINARY = "${pkgs.mongodb}/bin/mongod";
    };
    # Just as good.
    shellAliases = { vim = "nvim"; };
    # List packages installed in system profile. To search, run:
    # $ nix search ...
    systemPackages = with pkgs;
      [
        wget
        neovim
        utillinux
        pciutils
        lxappearance
        htop
        openvpn
        docker-compose
      ] ++ (with pkgs.unixtools; [ netstat ifconfig ]) # Basic network
      ++ [ nix-prefetch-git cachix ]; # Nix convinience
  };

  networking = {
    networkmanager.packages = [ pkgs.networkmanager_openvpn ];
    # Port's for work stuff.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9007 ];
    };
    # Give me those sweet interwebs
    networkmanager = { enable = true; };
    # No stupid DNS shennanigans
    resolvconf.dnsExtensionMechanism = false;
  };

  # Default shell.
  users.extraUsers.dlevym = { shell = pkgs.zsh; };

  # Backup shell.
  programs.zsh = { enable = true; };

  # Minimal bash config (for root)
  programs.bash.interactiveShellInit = "shopt -s autocd"; # autocd

  # Let me lock the screen. TODO Find alternatives.
  programs.slock.enable = true;

  # Documentation, documentation, documentation!
  documentation.man = {
    enable = true;
    generateCaches = true;
  };

  # List services that you want to enable:

  # Docker
  virtualisation.docker.enable = true;

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

  # Reuse an already-established connection when creating a new SSH session
  programs.ssh.extraConfig = ''
    ControlMaster auto
    ControlPath ~/.ssh/socket_%r@%h-%p
    ControlPersist 600
  '';

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "ctrl:nocaps";
    autoRepeatInterval = 25;
    autoRepeatDelay = 200;
    exportConfiguration = true;
    libinput = {
      enable = true; # Enable touchpad support
      touchpad = { disableWhileTyping = true; };
    };
    desktopManager = {
      session = [{
        name = "home-manager+awesomewm";
        start = ''
          # TODO Make ibus-daemon a systemctl --user service
          # NOTE Careful! IBUS will overwrite your layout unless you enable "Use system keyboard layout" option in Preferences -> Advanced
          /run/current-system/sw/bin/ibus-daemon -d -x

          exec $HOME/.local/share/xsession/xsession-awesome
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
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Gnome craziness.
  services.dbus.packages = with pkgs; [
    gnome3.dconf
    gnome3.adwaita-icon-theme
    gnome2.GConf
  ];

  # Key-Values and pears?
  services.redis.enable = true;

  # Documents, DOCUMENTS, DOCUMENTS!
  services.mongodb = {
    enable = true;
    # package = pkgs.mongodb-4_0;
  };

  # Don't bother me for passwords.
  security.polkit.enable = true;

  # Max file limits
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "8192";
    }
  ];

  # Make daily automatic upgrades.
  system.autoUpgrade.enable = true;

  # Remenber me, for longer.
  security.sudo.extraConfig = "Defaults        timestamp_timeout=300";

  # Bother me, less.
  services.gnome.gnome-keyring.enable = true;

  # !https://github.com/NixOS/nixpkgs/issues/16327
  services.gnome.at-spi2-core.enable = true;

  # Torrents
  services.transmission = { enable = true; };
}
