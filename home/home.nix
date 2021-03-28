let modules = [
    # My Shell configuration.
    "cli"

    # XDG Base Dir.
    "xdg"

    # The not quite C.
    "golang"

    # I cannot live without you, my one true love...
    "emacs"

    # Xmonad, the functional WM.
    "wm"

    # The functional lisp.
    "clj"

    # It's all there dude, in the ☁.
    "cloud"

    # Abandon hope, all that come here.
    "nodejs"

    # Normie Apps so I can pretend I am not a nerd.
    "apps"

    # What's going on out there?
    "io"
    ];
    toModulePath = (x: ./. + builtins.toPath "/modules/${x}/default.nix");
    moduleImports = map toModulePath modules;
in { self, config, pkgs, ... }: {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "dlevym";
  home.homeDirectory = "/home/dlevym";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";

  # Keyboard Layout
  home.keyboard = {
    layout = "us(altgr-intl)";
    options = [ "ctrl:nocaps" ];
  };

  # Be quiet, will you?
  news.display = "silent";

  # Modularize! Never compromise! 😎
  imports = moduleImports;
}
