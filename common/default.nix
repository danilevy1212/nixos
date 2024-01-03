{
  config,
  pkgs,
  unstable,
  stable,
  hostname,
  HOSTS,
  obsidianmd,
  ...
}: let
  stateVersion = config.system.nixos.release;
in {
  system.stateVersion = stateVersion;

  # Set your time zone.
  time.timeZone = "America/New_York";

  nix = {
    # Common NIX_PATH
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    settings = {
      trusted-users = ["root" "dlevym"];
      # Protect disk space
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      randomizedDelaySec = "15m";
      options = "--delete-older-than 15d";
    };
    package = pkgs.nixVersions.stable;
    # Protect nix-shell against garbage collection
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    config = {
      # Sorry, Stallman
      allowUnfree = true;
    };
  };

  # Booting
  boot = {
    # NixOS uses NTFS-3G for NTFS support.
    supportedFilesystems = ["ntfs"];

    # Cutting-edgyness
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Less eye-sore console font.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    dlevym = {
      # Default shell.
      shell = pkgs.zsh;
      isNormalUser = true;
      extraGroups = [
        # Docker
        "docker"
        # Enable ‘sudo’ for the user.
        "wheel"
        # Can use network-manager
        "networkmanager"
        # Pulse Audio
        "audio"
      ];
    };
  };

  # Enable sound with pipewire.
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Network configuration.
  networking = {
    hostName = "${hostname}";
    networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
      networkmanager-fortisslvpn
    ];
    # Port's for work stuff.
    firewall = {
      enable = true;
    };
    # Give me those sweet interwebs
    networkmanager = {enable = true;};
    # No stupid DNS shennanigans
    resolvconf.dnsExtensionMechanism = false;
  };

  # Backlight control
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      {
        keys = [224];
        events = ["key"];
        command = "/run/current-system/sw/bin/light -U 5";
      }
      {
        keys = [225];
        events = ["key"];
        command = "/run/current-system/sw/bin/light -A 5";
      }
    ];
  };

  # TODO Move this out of here
  # My user environment.
  home-manager = {
    # Home manager has access to system level dependencies.
    useGlobalPkgs = true;
    # Unclutter $HOME.
    useUserPackages = true;
    extraSpecialArgs = {
      inherit unstable;
      inherit stable;
      inherit hostname;
      inherit HOSTS;
      inherit obsidianmd;
      inherit stateVersion;
    };
    # Load my home-manager configuration.
    users.dlevym = import ./../home/home.nix;
    # Easier debugging
    verbose = true;
  };

  environment = {
    variables = {
      # !https://github.com/NixOS/nixpkgs/issues/16327
      NO_AT_BRIDGE = "1";

      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which could
      # cause race conditions.
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
    # Just as good.
    shellAliases = {vim = "nvim";};
    # Ensure all downloaded packages have auto completion info
    pathsToLink = ["/share/zsh"];
    # List packages installed in system profile. To search, run:
    # $ nix search ...
    systemPackages = with pkgs;
      [
        gitAndTools.gitFull
        neovim
        wget
        tree
        htop
        docker-compose
        inetutils
        dig
        openvpn
        lsof
        usbutils
        firefox
        lxappearance
        pciutils
        p7zip
        unzip
        gnome.dconf-editor
        (import ./../pkgs/colortest {inherit pkgs;})
      ]
      # Basic network
      ++ (with pkgs.unixtools; [netstat ifconfig])
      # Nix convenience
      ++ [nix-prefetch nix-prefetch-git cachix nix-tree];
  };

  # TODO  https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/networking/ssh/sshd.nix#L257
  #       Change the git clones of home-manager to use ssh instead of https.
  #       Then, in the README, explain how to set up ssh keys, using the /etc/ssh/ssh_host_ed25519_key.pub file
  #       as the public key to add to github.
  #       TODO  Is there a way to make sshd generate a keypair for the user, and then add the public key to github?
  #             Or make home-manager use the system ssh key? Or make home-manager generate a keypair?
  #       This enables us to use install the flake directly, without having to manually add the ssh key.
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Configure key-map in X11
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
      touchpad = {disableWhileTyping = true;};
    };
    desktopManager = {
      # TODO Make ibus-daemon a systemctl --user service
      session = [
        {
          name = "home-manager+awesomewm";
          start = ''
            # NOTE Careful! IBUS will overwrite your layout unless you enable "Use system keyboard layout" option in Preferences -> Advanced
            /run/current-system/sw/bin/ibus-daemon -d -x

            exec $HOME/.local/share/xsession/xsession-awesome
          '';
        }
      ];
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

  # Don't bother me for passwords.
  security.polkit.enable = true;

  # Remenber me, for longer.
  security.sudo.extraConfig = "Defaults        timestamp_timeout=300";

  # Max file limits
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "49152";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "65535";
    }
  ];

  # Allow greeters to use gnome-keyring
  security.pam.services.greeter.enableGnomeKeyring = true;

  # Documentation
  documentation.man = {
    enable = true;
    generateCaches = true;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # NOTE https://www.reddit.com/r/NixOS/comments/b255k5/comment/i8jpqum/?utm_source=share&utm_medium=web2x&context=3
  # Gnome craziness.
  programs.dconf.enable = true;

  # Default shell
  programs.zsh = {enable = true;};

  # See https://github.com/Mic92/nix-ld#how-does-nix-ld-work
  programs.nix-ld.enable = true;

  # Minimal bash config (for root)
  # autocd
  programs.bash.interactiveShellInit = "shopt -s autocd";

  # Connect mpv to my jellyfin instance automatically
  systemd.user.services = {
    "jellyfin-mpv-shim" = let
      dependencies = ["hm-graphical-session.target" "tray.target"];
    in {
      # FIXME  It's not auto-starting
      wants = dependencies;
      requires = dependencies;
      unitConfig = {
        Description = "jellyfin-mpv-shim";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${stable.jellyfin-mpv-shim}/bin/jellyfin-mpv-shim";
        Restart = "always";
      };
    };
  };

  # Bother me, less.
  services.gnome.gnome-keyring.enable = true;

  # Need to enable udisks2 on the system level
  services.udisks2.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Suspend when the lid closes (in case of laptop)
  services.logind.lidSwitch = "suspend";
}
