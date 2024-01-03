{
  stateVersion,
  ...
}: let
  # TODO  https://nixos.org/manual/nixos/stable/#sec-writing-modules Refactor this into a module.
  #       Each "host" imports this module that sets it's home-manager configuration.
  #       In turn, this will enable flake configuration that are only home-manager related.
  #       Useful for systems that are not NixOS.
  modules = [
    # XDG Base Dir.
    "xdg"

    # I cannot live without you, my one true love...
    "emacs"

    # My guilty pleasure
    "neovim"

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

    # A system admin best friend
    "python"

    # Window Management.
    "wm"

    # Normie Apps so I can pretend I am not a nerd.
    "apps"
  ];
  moduleImports = map (x: ./. +  "/modules/${x}") modules;
  # TODO  This should be forwarded from the host system.
  username = "dlevym";
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the paths it should manage.
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  # Be quiet, will you?
  news.display = "silent";

  # Modularize! Never compromise! 😎
  imports = moduleImports;
}
