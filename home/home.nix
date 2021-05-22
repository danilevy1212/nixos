let modules = [
    # My Shell configuration.
    "cli"

    # XDG Base Dir.
    "xdg"

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
    moduleImports = map (x: ./. + builtins.toPath "/modules/${x}") modules;
in { self, config, pkgs, ... }: {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "dlevym";
  home.homeDirectory = "/home/dlevym";

  # Be quiet, will you?
  news.display = "silent";

  # Modularize! Never compromise! 😎
  imports = moduleImports;
}
