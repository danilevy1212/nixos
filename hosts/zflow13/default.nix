{
  pkgs,
  userConfig,
  lib,
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
  # Folio reset derived from community guidance; see:
  # - https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551
  # - https://github.com/th3cavalry/GZ302-Linux-Setup (reload-hid_asus.service)
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
  # Shared serviceConfig for folio HID reset
  # - ExecStartPre guards: only reload if hid_asus is already loaded (no-op otherwise)
  # - ExecStart runs folioReset which reloads the module and kicks kbd backlight
  # - RemainAfterExit keeps the unit "active (exited)" for visibility
  hidAsusResetServiceConfig = {
    Type = "oneshot";
    # Only reload if hid_asus is currently loaded; still allow backlight restore
    ExecStartPre = "${pkgs.runtimeShell} -c '${pkgs.kmod}/bin/lsmod | ${pkgs.gnugrep}/bin/grep -q \"^hid_asus \" || exit 0'";
    ExecStart = folioReset;
    RemainAfterExit = true;
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../common/sunshine.nix
  ];

  # Kernel parameters tuned for ASUS GZ302 stability
  # - quiet suppresses benign ACPI firmware bugs (cosmetic; no functional impact)
  # - deep sleep avoids EC/HID resume quirks
  # - amd_pstate enables the modern CPU scaling driver
  # - ACPI OSI pair and enforce_resources coax ASUS firmware paths
  # - USB quirk targets the BT controller; prefer device-specific over global toggles
  boot.kernelParams = [
    # Suppress benign ACPI/firmware warnings from broken ASUS BIOS
    "quiet"
    # Use deep sleep by default — avoids EC/HID quirks on ASUS laptops.
    "mem_sleep_default=deep"
    # Bluetooth quirks
    "usbcore.quirks=13d3:3608:k"
    # Enable AMD P-State driver for better power management
    "amd_pstate=active"
    # Silence ACPI spam from broken firmware
    "acpi_osi=!"
    "acpi_osi=\"Windows 2020\""
    "acpi_enforce_resources=lax"
  ];

  # ASUS HID modules required for touchpad, keyboard backlight, and function keys
  boot.kernelModules = [
    "hid"
    "usbhid"
    "hid_generic"
    "hid_asus"
    "i2c-dev"
    "i2c-hid-acpi"
  ];
  # Module options derived from https://github.com/th3cavalry/GZ302-Linux-Setup
  # Covers: HID buffer sizing, BT/Wi-Fi stability, audio platform, WMI quirks, GPU runtime PM
  boot.extraModprobeConfig = ''
    # Enable ASUS touchpad functionality + backlight + larger HID buffer to prevent probe errors
    options hid_asus enable_touchpad=1 fnlock_default=0 kbd_backlight=1 max_hid_buflen=8192
    # Prevent Bluetooth from disconnecting
    options btusb enable_autosuspend=0

    # MediaTek MT7925E – disable ASPM to stop random disconnects
    options mt7925e disable_aspm=1

    # Audio quirks for GZ302 (ALSA + ACP70 platform)
    options snd-hda-intel probe_mask=1 model=asus-zenbook
    options snd_acp_pci enable=1
    options snd-soc-acp70 machine=acp70-asus

    # ASUS WMI – reduce fan-curve / thermal error spam in dmesg
    options asus_wmi dev_id=0x00110000
    options asus_nb_wmi wapf=1

    # AMDGPU driver tuning (all GPU params consolidated here)
    options amdgpu dc=1 gpu_recovery=1 ppfeaturemask=0xffffffff runpm=1 sg_display=0 dcdebugmask=0x10

    # Camera – shorter timeout, ignore small quirks
    options uvcvideo quirks=128 timeout=5000
  '';

  # Folio HID reset: reload hid_asus and restore keyboard backlight after graphical.target
  # Guards against early boot when module isn't loaded yet; mirrors upstream service logic
  systemd.services.asus-folio-reset = {
    description = "ROG Flow Z13 folio HID reset after GUI starts";
    wantedBy = ["graphical.target"];
    after = ["display-manager.service" "graphical.target"];
    serviceConfig = hidAsusResetServiceConfig;
  };

  # Folio HID reset on resume: ensures keyboard backlight and touchpad sanity after sleep.target
  systemd.services."asus-folio-reset-resume" = {
    description = "ROG Flow Z13 folio HID reset after resume";
    wantedBy = ["sleep.target"];
    after = ["sleep.target"];
    serviceConfig = hidAsusResetServiceConfig;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # NetworkManager: disable MAC randomization and powersave for MT7925E stability
  # Mirrors upstream recommendations; combined with udev rule below for redundancy
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    settings = {
      device = {
        "wifi.scan-rand-mac-address" = false;
        "wifi.backend" = "wpa_supplicant";
      };
      connection = {
        # 2 = disabled
        "wifi.powersave" = 2;
      };
      main = {
        "wifi.scan-rand-mac-address" = false;
      };
    };
  };

  # Udev rules from upstream GZ302 script:
  # - Wi-Fi powersave off via iw when interface appears ($env{INTERFACE} is udev's native expansion)
  # - I/O schedulers tuned per device type (NVMe, SATA SSD, HDD)
  services.udev.extraRules = ''
    # Disable Wi-Fi powersave when interface appears (MT7925E stability)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="${pkgs.iw}/bin/iw dev $env{INTERFACE} set power_save off"

    # I/O-scheduler hints (NVMe → none fallback mq-deadline / SATA-SSD → mq-deadline / HDD → bfq)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # Hardware DB override: force correct touchpad detection and sensitivity for ASUS folio
  # Vendor ID 0b05, Product ID 1a30; override ensures libinput sees it as a touchpad, not a mouse
  services.udev.extraHwdb = ''
    # ASUS ROG Flow Z13 folio touchpad override (fixes detection + sensitivity)
    evdev:input:b0003v0b05p1a30*
     ID_INPUT_TOUCHPAD=1
     ID_INPUT_MULTITOUCH=1
     ID_INPUT_MOUSE=0
     EVDEV_ABS_00=::100
     EVDEV_ABS_01=::100
     EVDEV_ABS_35=::100
     EVDEV_ABS_36=::100
  '';

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
    # GZ302 touchpad tuning (from gz302_setup.sh libinput config)
    inputClassSections = [
      ''
        Section "InputClass"
          Identifier "ASUS GZ302 Touchpad"
          MatchIsTouchpad "on"
          MatchDevicePath "/dev/input/event*"
          MatchProduct "ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad"
          Driver "libinput"
          Option "DisableWhileTyping" "off"
          Option "TappingDrag" "on"
          Option "TappingDragLock" "on"
          Option "MiddleEmulation" "on"
          Option "NaturalScrolling" "true"
          Option "ScrollMethod" "twofinger"
          Option "HorizontalScrolling" "on"
          Option "SendEventsMode" "enabled"
        EndSection
      ''
    ];
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

  # ASUS userspace stack: asusd for keyboard/fan/profile control; supergfxd for GPU switching
  # See https://asus-linux.org/guides/nixos/
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
  services.supergfxd = {
    enable = true;
  };

  # Power management stack for this host:
  # - power-profiles-daemon provides powerprofilesctl (performance/balanced/power-saver)
  # - switcherooControl enables GPU switching orchestration (complements supergfxd)
  services.power-profiles-daemon.enable = true;
  services.switcherooControl.enable = true;

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

  # Use latest mainline kernel (6.17+) on this host for newest AMD/ASUS fixes
  # Common config pins 6.16; this override is zflow13-specific for testing newer kernels
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # ROCm support for GPU compute (currently disabled in favor of Vulkan/lmstudio)
  # Kept for when ROCm 7 lands in nixpkgs and ollama becomes viable again
  nixpkgs.config.rocmSupport = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  # Enable AMD CPU microcode and all redistributable firmware (WiFi, BT, GPU)
  hardware.enableRedistributableFirmware = true;

  # Emergency-only 8GB swapfile: lowest priority (-2) so zram is preferred
  # Discard option hints TRIM to NVMe; only touched when zram is exhausted
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
