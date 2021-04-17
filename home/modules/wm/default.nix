{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # Development.
    stack
    cabal-install
    haskellPackages.hoogle

    # Notifications
    dunst

    # FIXME Remove/Replace once I use awesomewm
    dmenu

    # TODO Take out when I deprecate polybar
    xmonad-log

    # Let there be control over the sound!
    pulsemixer
    pavucontrol
    playerctl

    # Control the screens!
    arandr
    xorg.xkill

    # xXxScReeN_SH0TSxXx
    flameshot

    # Development language FIXME Replace with Awesome/lua tools.
    # haskell-language-server

    # Drag and Drop convinience
    dragon-drop
  ];

  home.sessionVariables = {
    # Where stack snapshots are located.
    STACK_ROOT = "$XDG_DATA_HOME/stack";

    # Default theme.
    GTK_THEME = "Nordic";
  };

  # Create the xmonad xsession.
  xsession = {
    scriptPath = ".xsession-hm";
    pointerCursor = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
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

  # ALERT ME!
  services.dunst = {
    enable = true;
    iconTheme = {
      name = "breeze";
      package = pkgs.breeze-icons;
    };
    settings = {
      global = {
        allow_markup = true;
        format = "<b><u>%a</u></b>\\n%s\\n\\n%b";
        sort = false;
        alignment = "left";
        indicate_hidden = true;
        bounce_freq = 0;
        word_wrap = true;
        ignore_newline = false;
        hide_duplicates_count = true;
        geometry = "400x50+15+40";
        transparency = 15;
        idle_threshold = 0;
        monitor = 0;
        follow = "keyboard";
        sticky_history = true;
        history_length = 15;
        show_indicators = false;
        separator_height = 2;
        padding = 9;
        horizontal_padding = 12;
        line_height = 1;
        separator_color = "frame";
        icon_position = "left";
        frame_width = 1;
        frame_color = "#458588";
        corner_radius = 14;
        max_icon_size = 80;
      };
      urgency_low = {
        foreground = "#88c0d0";
        background = "#282828";
        timeout = 4;
      };
      urgency_normal = {
        foreground = "#d79921";
        background = "#282828";
        timeout = 6;
      };
      urgency_critical = {
        foreground = "#cc241d";
        background = "#282828";
        timeout = 8;
      };
    };
  };

  # TODO I may replace this with TaffyBar eventually.
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override { pulseSupport = true; };
    extraConfig = builtins.readFile "${builtins.toString ./.}/config.ini";
    script = builtins.readFile "${builtins.toString ./.}/run-polybar.sh";
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
