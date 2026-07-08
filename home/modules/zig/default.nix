{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.userConfig.modules.python;
in {
  options.userConfig.modules.zig.enable = mkEnableOption "Enable zig support";
  config = lib.mkIf cfg.enable {
    # Install latest stable
    home.packages = [pkgs.zig_0_16];
  };
}
