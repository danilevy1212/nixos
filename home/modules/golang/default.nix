{
  config,
  lib,
  ...
}: let
  goPath = ".cache/go";
  cfg = config.userConfig.modules.golang;
in
  with lib; {
    options.userConfig.modules.golang = {
      enable = mkEnableOption "Enable golang";
      goPath = mkOption {
        type = lib.types.str;
        default = goPath;
        description = "Path to store go packages";
      };
      addPath = mkOption {
        type = lib.types.bool;
        default = true;
        description = "Add goPath bin to path";
      };
    };

    config = mkIf cfg.enable {
      programs.go = {
        enable = true;
        goPath = cfg.goPath;
      };

      home.sessionPath = mkIf cfg.addPath ["$HOME/${goPath}/bin"];
    };
  }
