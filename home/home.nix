{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  modules = [
    # XDG Base Dir.
    "xdg"

    # I cannot live without you, my one true love...
    "emacs"

    # My Shell configuration.
    "cli"

    # Abandon hope, all that come here.
    "nodejs"

    # It's all there dude, in the ☁.
    "cloud"

    # What's going on out there?
    "io"

    # Rust
    "rust"

    # Golang
    "golang"

    # Window Management.
    "wm"

    # Normie Apps so I can pretend I am not a nerd.
    "apps"
  ];
  moduleImports = map (x: ./. + builtins.toPath "/modules/${x}") modules;
  username =
    if pkgs.stdenv.isDarwin
    then "dlevy"
    else "dlevym";
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the paths it should manage.
  home = {
    inherit username;
    homeDirectory =
      if pkgs.stdenv.isLinux
      then "/home/dlevym"
      else "/Users/dlevy";
    stateVersion = "22.11";
  };

  # Be quiet, will you?
  news.display = "silent";

  # Modularize! Never compromise! 😎
  imports = moduleImports;
}
