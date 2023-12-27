{
  config,
  lib,
  pkgs,
  hostname,
  stable,
  ...
}: {
  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [
    firefox
    lxappearance
    pciutils
    p7zip
    unzip
    gnome.dconf-editor
  ];

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
        "wheel" # Enable ‘sudo’ for the user.
        "networkmanager" # Can use network-manager
        "audio" # Pulse Audio
      ];
    };
  };

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

  # See https://github.com/Mic92/nix-ld#how-does-nix-ld-work
  programs.nix-ld.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
      touchpad = {disableWhileTyping = true;};
    };
    desktopManager = {
      session = [
        {
          name = "home-manager+awesomewm";
          start = ''
            # TODO Make ibus-daemon a systemctl --user service
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

  # NOTE https://www.reddit.com/r/NixOS/comments/b255k5/comment/i8jpqum/?utm_source=share&utm_medium=web2x&context=3
  # Gnome craziness.
  programs.dconf.enable = true;

  # Don't bother me for passwords.
  security.polkit.enable = true;

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

  # Documentation, documentation, documentation!
  documentation.man = {
    enable = true;
    generateCaches = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  home-manager.users.dlevym = import ./../../home/home.nix;

  ## List services that you want to enable:
  # Docker
  virtualisation.docker.enable = true;

  # Connect mpv to my jellyfin instance automatically
  systemd.user.services = {
    "jellyfin-mpv-shim" = let
      dependencies = ["hm-graphical-session.target" "tray.target"];
    in {
      # FIXME  Not auto-starting
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
  # Remenber me, for longer.
  security.sudo.extraConfig = "Defaults        timestamp_timeout=300";

  # Bother me, less.
  services.gnome.gnome-keyring.enable = true;

  # FIXME This doesn't work
  # Allow greeters to use gnome-keyring
  security.pam.services.greeter.enableGnomeKeyring = true;

  # Need to enable udisks2 on the system level
  services.udisks2 = {
    enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Suspend when the lid closes (in case of laptop)
  services.logind.lidSwitch = "suspend";
}
