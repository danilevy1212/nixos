{
  pkgs,
  userConfig,
  ...
}: let
  # TODO  This whole llm-studio setup should + certs should be moved to it's own module
  # SSL configuration variables
  sslDir = "/etc/ssl/llm-studio";
  certName = "openai.local";
  certFile = "${certName}.pem";
  keyFile = "${certName}-key.pem";
  caCertFile = "rootCA.pem";
  caKeyFile = "rootCA-key.pem";
  lmstudioStart = pkgs.writeShellScript "lmstudio-start.sh" ''
    set -euo pipefail
    # Start API server in the background; it will exit once it connects.
    "${pkgs.lmstudio}/bin/lms" server start --port 1234 --cors &
    # Now start the app minimized as a background service
    exec "${pkgs.lmstudio}/bin/lm-studio" --run-as-service --minimized
  '';
  # From https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551
  folioReset = pkgs.writeShellScript "asus-folio-reset.sh" ''
    # Reload ASUS HID
    ${pkgs.kmod}/bin/modprobe -r hid_asus
    ${pkgs.kmod}/bin/modprobe hid_asus
    # Restore keyboard backlight
    [ -e /sys/class/leds/asus::kbd_backlight/brightness ] && echo 3 > /sys/class/leds/asus::kbd_backlight/brightness
  '';
  # Generate certificates in the Nix store
  llmStudioLocalCerts =
    pkgs.runCommand "llm-studio-certs" {
      buildInputs = [pkgs.mkcert];
    } ''
      mkdir -p $out/ca $out/certs
      export CAROOT=$out/ca

      # Create CA
      mkcert -install

      # Create leaf cert
      mkcert \
        -cert-file $out/certs/${certFile} \
        -key-file  $out/certs/${keyFile} \
        ${certName}

      chmod 0644 $out/certs/${certFile}
      chmod 0644 $out/certs/${keyFile}
      chmod 0644 $out/ca/${caCertFile}
      chmod 0644 $out/ca/${caKeyFile}
    '';
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.kernelParams = [
    # Work around USB autosuspend on the internal hub
    "usbcore.autosuspend=0"
    # Use deep sleep by default — avoids EC/HID quirks on ASUS laptops.
    "mem_sleep_default=deep"
    # Force the AMD Display Core (DCN) driver path on (already default, but explicit).
    "amdgpu.dc=1"
    # Disable scatter-gather scanout. Keeps scanout buffers contiguous,
    # which can prevent the brief “missing sliver” glitches during flips.
    "amdgpu.sg_display=0"
    # See https://discussion.fedoraproject.org/t/glitch-that-appears-casually-on-screen-of-an-amd-laptop-60-hz-running-fedora-kde-plasma/142323?utm_source=chatgpt.com
    "amdgpu.dcdebugmask=0x10"
    # Bluetooth quirks
    "usbcore.quirks=13d3:3608:k"
    # Enable AMD P-State driver for better power management
    "amd_pstate=active"
  ];

  # ASUS HID quirks (touchpad/extra keys) and AMD GPU
  boot.kernelModules = [
    "hid"
    "usbhid"
    "hid_generic"
    "hid_asus"
    "i2c-dev"
    "i2c-hid-acpi"
  ];
  boot.extraModprobeConfig = ''
    # Enable ASUS touchpad functionality
    options hid_asus enable_touchpad=1
    # Prevent Bluetooth from disconnecting
    options btusb enable_autosuspend=0
  '';

  # Run once at boot
  systemd.services.asus-folio-reset = {
    description = "ROG Flow Z13 folio HID reset after GUI starts";
    wantedBy = ["graphical.target"];
    after = ["display-manager.service" "graphical.target"];
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
  boot.loader.systemd-boot.configurationLimit = 5;
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

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11 and GPU drivers
  services.xserver = {
    videoDrivers = ["amdgpu"];
    xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
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
    # LLMs
    lmstudio
    vulkan-tools
    llmStudioLocalCerts
    # ROCm
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
    rocmPackages.rocm-core
    rocmPackages.rocmPath
    rocmPackages.rocm-runtime
    rocmPackages.rocm-device-libs
    rocmPackages.rocblas
    rocmPackages.rccl
  ];

  # 1password and its GUI
  programs._1password = {
    enable = true;
  };
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [userConfig.username];
  };

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # See https://asus-linux.org/guides/nixos/
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
  services.supergfxd = {
    enable = true;
  };

  systemd.user.services.lmstudio-headless = {
    description = "LM Studio (server then minimized app)";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = lmstudioStart;
      Restart = "on-failure";
      RestartSec = "3s";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # HACK  To be able to use https://public.amplenote.com/WykvBZZSXReMcVFRrjrhk4mS (Ample Copilot)
  #       I fool the plugin into believing that It is connecting to openai.
  #       I also create a fake certificate so Firefox allows the connection
  #       This is ugly as sin, but it works!
  networking.hosts = {
    "127.0.0.1" = ["openai.local" "localhost"];
  };
  # Install CA certificate in system trust store for automatic browser trust
  security.pki.certificates = [
    (builtins.readFile "${llmStudioLocalCerts}/ca/${caCertFile}")
  ];
  # Create symlinks to leaf certificates for llm-studio service
  systemd.tmpfiles.rules = [
    "d ${sslDir} 0755 root root -"
    "L+ ${sslDir}/${certFile} - - - - ${llmStudioLocalCerts}/certs/${certFile}"
    "L+ ${sslDir}/${keyFile} - - - - ${llmStudioLocalCerts}/certs/${keyFile}"
  ];
  # Make Firefox trust the CA as well, so it allows connections to openai.local
  programs.firefox = {
    policies.Certificates = {
      ImportEnterpriseRoots = true;
      Install = ["${llmStudioLocalCerts}/ca/${caCertFile}"];
    };
    preferences."security.enterprise_roots.enabled" = true;
  };
  # Reverse proxy because the stupid plugin automatically upgrades to https
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."openai.local" = {
      serverName = "openai.local";
      serverAliases = ["localhost"];

      # Let the module add `listen 443 ssl;` AND the `ssl_certificate` lines
      onlySSL = true;
      http2 = true;

      sslCertificate = "${sslDir}/${certFile}";
      sslCertificateKey = "${sslDir}/${keyFile}";

      # Route back to lmstudio
      locations."/" = {
        proxyPass = "http://127.0.0.1:1234";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };

  # LLMs interface
  services.ollama = {
    # TODO  I've given up, let's do lmstudio with vulkan backend instead. When ROCm 7 lands on nixos, I'll try again.
    enable = false;
    acceleration = "rocm";
    environmentVariables = {
      # NOTE  See https://www.amplenote.com/plugins/WykvBZZSXReMcVFRrjrhk4mS
      OLLAMA_ORIGINS = "amplenote-handler://*,https://plugins.amplenote.com";
      OLLAMA_FLASH_ATTENTION = "true";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
    rocmOverrideGfx = "11.5.1";
  };
  # Nice Web UI
  services.open-webui = {
    enable = true;
    # NOTE  See https://github.com/NixOS/nixpkgs/pull/446013#issuecomment-3335605779
    package = pkgs.open-webui.overridePythonAttrs (oldAttrs: {
      dependencies =
        oldAttrs.dependencies
        ++ [
          pkgs.python3Packages.itsdangerous
        ];
    });
  };

  # Enable ROCm and AMD GPU drivers
  nixpkgs.config.rocmSupport = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  # AMD CPU microcode updates
  hardware.enableRedistributableFirmware = true;

  # Emergency-only 8GB swapfile - absolutely last resort (very low priority)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      # 8GB in MB
      size = 8 * 1024;
      # Hint TRIM for NVMe; harmless elsewhere.
      options = ["discard"];
      # Lowest priority so it's only touched if zram is exhausted.
      priority = -2;
    }
  ];
}
