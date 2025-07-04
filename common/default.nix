{
  config,
  pkgs,
  userConfig,
  stable,
  ...
}: let
  stateVersion = config.system.nixos.release;
  username = userConfig.username;
  discover-wrapped = with pkgs;
    symlinkJoin {
      name = "discover-flatpak-backend";
      paths = [kdePackages.discover];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/plasma-discover --add-flags "--backends flatpak"
      '';
    };
in {
  system.stateVersion = stateVersion;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  nix = {
    settings = {
      trusted-users = ["root" username];
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

    # Keep things stable, mirror Ubuntu
    kernelPackages = pkgs.linuxPackages_6_14;
  };

  # Less eye-sore console font.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    "${username}" = {
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
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Network configuration.
  networking = {
    networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
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

  # My user environment.
  home-manager = {
    # Home manager has access to system level dependencies.
    useGlobalPkgs = true;
    # Unclutter $HOME.
    useUserPackages = true;
    # Load my home-manager configuration.
    users."${username}" = import ./../home;
    # Easier debugging
    verbose = true;
    # In case of collision, use a .backup file.
    backupFileExtension = "backup";
  };
  hardware.enableAllFirmware = true;

  # HW Acceleration for video
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva
      libvdpau
    ];
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    # Japanese input
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
        ];
      };
    };
    extraLocaleSettings = {
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
  };

  environment = {
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
    ];
    variables = {
      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which could
      # cause race conditions.
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";

      # EDITOR
      EDITOR = "nvim";

      # Prefer wayland when available
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # Help with stuttering
      SDL_VIDEODRIVER = "wayland";
    };
    # Just as good.
    shellAliases = {
      vim = "nvim";
      wine = "WINEPREFIX=~/.local/share/wine wine";
      k = "kubectl";
      suspend = "systemctl suspend";
      poweroff = "systemctl poweroff";
    };
    # Ensure all downloaded packages have auto completion info
    pathsToLink = ["/share/zsh"];
    # List packages installed in system profile. To search, run:
    # $ nix search ...
    systemPackages = with pkgs;
      [
        gitAndTools.gitFull
        neovim
        lshw
        wget
        tree
        htop
        docker-compose
        inetutils
        dig
        iperf
        openvpn
        lsof
        usbutils
        firefox
        lxappearance
        pciutils
        p7zip
        unzip
        dconf-editor
        memtest86plus
        smartmontools
        # Audio (pulseaudio under pipewire)
        pulseaudio
        # KDE extras
        ocs-url
        discover-wrapped
        # TV calibration
        read-edid
        edid-decode
        # wayland
        wl-clipboard-rs
        wayland-utils
        # opencl
        clinfo
        # opengl
        glxinfo
        # vulkan
        vulkan-tools
        # sensor data
        lm_sensors
        # Verify video HW acceleration, see https://nixos.wiki/wiki/Accelerated_Video_Playback
        libva-utils
        nvtopPackages.full
        # k8s (client + local dev)
        minikube
        kubectl
      ]
      # Basic network
      ++ (with pkgs.unixtools; [netstat nmap ifconfig])
      # Nix convenience
      ++ [nix-prefetch nix-prefetch-git cachix nix-tree]
      ++ # Windows compatibility, just in case
      [
        wineWowPackages.staging
        winetricks
      ];
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

  # plasma 6
  services.desktopManager = {
    plasma6 = {
      enable = true;
      enableQt5Integration = true;
    };
  };

  # Greeter
  services.displayManager = {
    sddm = {
      enable = true;
      enableHidpi = true;
      wayland.enable = true;
    };
  };

  # Configure key-map in X11
  services.xserver = {
    enable = true;
    autoRepeatInterval = 25;
    autoRepeatDelay = 200;
    exportConfiguration = true;
    xkb = {
      variant = "altgr-intl";
      options = "ctrl:nocaps";
      layout = "us";
    };
    desktopManager = {
      session = [
        {
          name = "home-manager+awesomewm";
          start = ''
            GTK_IM_MODULE="fcitx" QT_IM_MODULE="fcitx" ${config.i18n.inputMethod.package}/bin/fcitx5 -d

            exec $HOME/.local/share/xsession/xsession-awesome
          '';
        }
      ];
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
      value = "524288";
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
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = stable.pinentry-qt;
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

  # Register AppImage files as a binary type to binfmt_misc
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Connect mpv to my jellyfin instance automatically
  systemd.user.services = {
    "jellyfin-mpv-shim" = {
      enable = true;
      wantedBy = ["graphical-session.target"];

      script = ''
        retry_count=0
        max_retries=3
        initial_delay=1.5

        while ! ${pkgs.unixtools.ping}/bin/ping -c 1 -W 1 google.com; do
          retry_count=$((retry_count + 1))
          if [ "$retry_count" -ge "$max_retries" ]; then
            echo "Failed to reach google.com after $max_retries attempts."
            exit 1
          fi
          sleep $((initial_delay ** retry_count))
        done
        exec ${stable.jellyfin-mpv-shim}/bin/jellyfin-mpv-shim
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
    };
  };

  # Enable KDE Connect
  programs.kdeconnect.enable = true;

  # Bother me, less.
  services.gnome.gnome-keyring.enable = true;

  # Need to enable udisks2 on the system level
  services.udisks2.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Suspend when the lid closes (in case of laptop)
  services.logind.lidSwitch = "suspend";

  # BIOS Upgrades
  services.fwupd.enable = true;

  # Run in any distro, ask questions later
  services.flatpak.enable = true;
  systemd.services.addFlathubRepo = {
    description = "Add the Flathub repository to flatpak";
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
}
