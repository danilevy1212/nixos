{
  config,
  lib,
  pkgs,
  ...
}: {
  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [firefox lxappearance];

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
      isNormalUser = true;
      extraGroups = [
        # Docker
        "docker"
        "wheel" # Enable ‘sudo’ for the user.
        "networkmanager" # Can use network-manager
        "audio" # Pulse Audio
      ];
    };
    # Default shell.
    extraUsers.dlevym = {shell = pkgs.zsh;};
  };

  boot = {
    # NixOS uses NTFS-3G for NTFS support.
    supportedFilesystems = ["ntfs"];

    # Cutting-edgyness
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [mozc];
    };
  };

  # Less eye-sore console font.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  networking = {
    networkmanager.plugins = [pkgs.networkmanager-openvpn];
    # Port's for work stuff.
    firewall = {
      enable = true;
    };
    # Give me those sweet interwebs
    networkmanager = {enable = true;};
    # No stupid DNS shennanigans
    resolvconf.dnsExtensionMechanism = false;
  };

  # Let me lock the screen. TODO Find alternatives.
  programs.slock.enable = true;

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

  # Gnome craziness.
  services.dbus.packages = with pkgs; [
    dconf
    gnome3.adwaita-icon-theme
    gnome2.GConf
  ];

  # Don't bother me for passwords.
  security.polkit.enable = true;

  # Max file limits
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65535";
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

  home.users.dlevym = import ./../../home/home.nix;

  ## List services that you want to enable:
  # Docker
  virtualisation.docker.enable = true;

  # Remenber me, for longer.
  security.sudo.extraConfig = "Defaults        timestamp_timeout=300";

  # Bother me, less.
  services.gnome.gnome-keyring.enable = true;
}
