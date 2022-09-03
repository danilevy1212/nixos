{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux (let
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
in {
  home = {
    packages = with pkgs; [
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
    };

    # For more comfy development, link configuration directly.
    activation = {
      linkConfWithAwesome = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -L ${config.xdg.configHome}/awesome ]
        then
        $DRY_RUN_CMD ln -s $VERBOSE_ARG \
            /etc/nixos/home/modules/wm/conf ${config.xdg.configHome}/awesome
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
  xdg.dataFile."awesome".source = "${pkgs.awesome}/share/awesome";

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
    vSync = true;
    activeOpacity = 1.0;
    inactiveOpacity = 0.9;
    fade = true;
    fadeDelta = 5;
    shadow = true;
    shadowOpacity = 0.75;
  };
})
