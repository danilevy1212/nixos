{ pkgs, ... }:

{
  home.packages = [
    pkgs.rustup
  ];

  home.sessionVariables = {
    RUSTUP_HOME="$XDG_DATA_HOME/rustup";
  };
}
