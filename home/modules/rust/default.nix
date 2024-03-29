{
  pkgs,
  lib,
  config,
  unstable,
  ...
}:
with lib; let
  cfg = config.userConfig.modules.rust;
in {
  options = {
    userConfig = {
      modules = {
        rust = {
          enable = mkEnableOption "Install rustup and setup cargo.";
        };
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = with unstable; [
      rustup
    ];

    home.sessionVariables = {
      RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
    };

    home.sessionPath = [
      "${config.home.sessionVariables.CARGO_HOME}/bin"
    ];
  };
}
