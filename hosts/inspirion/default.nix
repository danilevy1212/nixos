# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  userConfig,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  };

  # Touchpad settings
  services.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
    };
  };

  # NOTE nvidia options taken from https://nixos.wiki/wiki/Nvidia#sync_mode
  services.xserver = {
    dpi = 144;
    # Enable external monitor through discrete GPU
    videoDrivers = [
      "nvidia"
    ];
  };
  # Enable opengl support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Use discrete GPU to render the display
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

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

  # Tell me the power!
  systemd.services.upower.enable = true;

  # Notify battery status
  services.upower.enable = true;
}
