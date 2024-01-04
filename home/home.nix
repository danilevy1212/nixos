let
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
  moduleImports = map (x: ./. + "/modules/${x}") modules;
in {
  # Be quiet, will you?
  news.display = "notify";

  # Modularize! Never compromise! 😎
  imports =
    moduleImports
    ++ [
      # Core "home" settings.
      ./core.nix
    ];
}
