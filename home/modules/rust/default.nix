{pkgs, ...}: let
  CARGO_HOME = "$XDG_DATA_HOME/cargo";
in {
  home.packages = [
    pkgs.rustup
  ];

  home.sessionVariables = {
    RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
    CARGO_HOME = "${CARGO_HOME}";
  };

  home.sessionPath = [
    "${CARGO_HOME}/bin"
  ];
}
