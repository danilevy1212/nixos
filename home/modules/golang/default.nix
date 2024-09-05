{
  config,
  lib,
  pkgs,
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

      home.packages = with pkgs; [
        # Pretend golang is an interpreted language
        yaegi
        rlwrap
      ];

      # Make yaegi easier to use
      home.shellAliases = {
        yaegi = "rlwrap yaegi";
      };

      home.sessionPath = mkIf cfg.addPath ["$HOME/${goPath}/bin"];
    };
  }
