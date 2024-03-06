{
  config,
  lib,
  pkgs,
  ...
}: let
  awesome-wm-widgets = with pkgs;
    lua.pkgs.toLuaModule (stdenv.mkDerivation rec {
      name = "awesome-wm-widgets";
      pname = name;
      version = "scm-1";
      src = fetchGit {
        name = "awesome-wm-widgets";
        url = "https://github.com/streetturtle/awesome-wm-widgets";
        ref = "master";
        rev = "01a4f428e0361f4222e8d2f14607fb03bbd6d94e";
      };
      buildInputs = [lua];

      installPhase = ''
        mkdir -p $out/lib/lua/${lua.luaversion}/
        cp -r . $out/lib/lua/${lua.luaversion}/${name}/
        printf "package.path = '$out/lib/lua/${lua.luaversion}/?/init.lua;' ..  package.path\nreturn require((...) .. '.init')\n" > $out/lib/lua/${lua.luaversion}/${name}.lua
      '';
    });
  cfg = config.userConfig.modules.gui;
in {
  options.userConfig.modules.gui = {
    enable = lib.mkEnableOption "Enable GUI";
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # File management.
        spaceFM

        # Let there be control over the sound!
        pulsemixer
        pavucontrol
        playerctl
        easyeffects
        helvum

        # Control the screens!
        arandr
        xorg.xkill

        # xXxScReeN_SH0TSxXx
        flameshot
        simplescreenrecorder

        # Drag and Drop convenience
        xdragon

        # For REPL sake
        lua
        rlwrap

        # battery indicator
        acpi
      ];

      sessionVariables = {
        # Default theme.
        GTK_THEME = "Nordic";
        # default file-browser
        FILEMANAGER = "spacefm";
      };

      # For more comfy development, link configuration directly.
      activation = {
        linkConfWithAwesome = lib.hm.dag.entryAfter ["writeBoundary"] ''
          if [ ! -L ${config.xdg.configHome}/awesome ]
          then
          $DRY_RUN_CMD ln -s $VERBOSE_ARG \
              /etc/nixos/home/modules/gui/conf ${config.xdg.configHome}/awesome
          fi
        '';
      };

      # Don't manage the keyboard layout.
      keyboard = null;
    };

    # Create the awesome session.
    xsession = {
      enable = true;
      scriptPath = "${config.home.homeDirectory}/.local/share/xsession/xsession-awesome";
      windowManager.awesome = {
        enable = true;
        luaModules = [awesome-wm-widgets];
      };
    };

    home.pointerCursor = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

    # Link for the LSP
    xdg = {
      mimeApps = {
        defaultApplications = {
          # Make brave default browser
          "x-scheme-handler/http" = ["brave-browser.desktop"];
          "x-scheme-handler/https" = ["brave-browser.desktop"];
          # Make mpv default video player
          "video/x-matroska" = ["mpv.desktop"];
        };
      };
      dataFile."awesome".source = "${pkgs.awesome}/share/awesome";
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
        name = "Sarasa UI J";
        size = 10;
        package = sarasa-gothic;
      };
    };

    # Be pretty again.
    services.picom = {
      enable = true;
      backend = "glx";
      activeOpacity = 1.0;
      inactiveOpacity = 0.9;
      fade = true;
      fadeDelta = 5;
      shadow = true;
      shadowOpacity = 0.75;
    };

    # A pretty, modern, terminal emulator.
    programs.alacritty = {
      enable = true;
      settings = {
        # TODO  Switch to Ioveska Nerd Font + Sarasa Mono J backup (I need to switch to Kitty, alacritty doesn't support font fallback), see https://github.com/alacritty/alacritty/issues/957
        font = {
          normal = {family = "Sarasa Mono J";};
          bold = {family = "Sarasa Mono J";};
          italic = {family = "Sarasa Mono J";};
          bold_italic = {family = "Sarasa Mono J";};
          size = 10.0;
        };
        window = {
          decorations_theme_variant = "Dark";
          opacity = 0.9;
        };
        colors = {
          primary = {
            background = "#2e3440";
            foreground = "#d8dee9";
            dim_foreground = "#a5abb6";
          };
          cursor = {
            text = "#2e3440";
            cursor = "#d8dee9";
          };
          vi_mode_cursor = {
            text = "#2e3440";
            cursor = "#d8dee9";
          };
          selection = {
            text = "CellForeground";
            background = "#4c566a";
          };
          search = {
            matches = {
              foreground = "CellBackground";
              background = "#88c0d0";
            };
          };
          normal = {
            black = "#3b4252";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#88c0d0";
            white = "#e5e9f0";
          };
          bright = {
            black = "#4c566a";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#8fbcbb";
            white = "#eceff4";
          };
          dim = {
            black = "#373e4d";
            red = "#94545d";
            green = "#809575";
            yellow = "#b29e75";
            blue = "#68809a";
            magenta = "#8c738c";
            cyan = "#6d96a5";
            white = "#aeb3bb";
          };
          footer_bar = {
            background = "#434c5e";
            foreground = "#d8dee9";
          };
        };
      };
    };

    # Nordic Terminal
    xresources.extraConfig = builtins.readFile (pkgs.fetchzip {
        url = "https://github.com/arcticicestudio/nord-xresources/archive/v0.1.0.tar.gz";
        sha256 = "1bhlhlk5axiqpm6l2qaij0cz4a53i9hcfsvc3hw9ayn75034xr93";
      }
      + "/src/nord");

    programs.rofi = {
      enable = true;
    };
  };
}
