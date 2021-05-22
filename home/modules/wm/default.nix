{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # Let there be control over the sound!
    pulsemixer
    pavucontrol
    playerctl

    # Control the screens!
    arandr
    xorg.xkill

    # xXxScReeN_SH0TSxXx
    flameshot

    # Drag and Drop convenience
    dragon-drop

    # Do as sudo, graphically
    gksu

    # Enable awesome-client
    rlwrap

    # For REPL sake
    lua5_4
  ];

  home.sessionVariables = {
    # Default theme.
    GTK_THEME = "Nordic";
  };

  # Don't manage the keyboard layout.
  home.keyboard = null;

  # Create the awesome session.
  xsession = {
    enable = true;
    scriptPath =
      "${config.home.homeDirectory}/.local/share/xsession/xsession-awesome";
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks-nix
        vicious
        # TODO lain
      ];
    };
    pointerCursor = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };
  };

  # Link for the LSP
  xdg.dataFile."awesome".source = "${pkgs.awesome}/share/awesome";

  # NOTE For more comfy development, comment this block and create a symlink
  # between ./conf and ~/.config/awesome
  # (ln -sL # /etc/nixos/home/modules/wm/conf/ ~/.config/awesome).
  # When you are done, uncomment this block, remove the link and
  # `nixos-rebuild switch`
  home.file = {
    "awesome" = {
      source = ./conf;
      target = "./.config/awesome";
    };
  };

  # Make me pretty!
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
    font = {
      name = "Noto Sans";
      package = noto-fonts;
    };
  };

  # Be pretty again.
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    activeOpacity = "1.0";
    inactiveOpacity = "0.9";
    fade = true;
    fadeDelta = 5;
    shadow = true;
    shadowOpacity = "0.75";
    blur = true;
  };
}
