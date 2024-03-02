{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  ipythonDir = "${config.xdg.configHome}/ipython";
  cfg = config.userConfig.modules.python;
in {
  options.userConfig.modules.python.enable = mkEnableOption "Enable python support";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (python3.withPackages (ps: with ps; [ipython requests]))
    ];

    home.activation = {
      ipythonXdg = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d ${ipythonDir} ]; then
            mkdir -p ${ipythonDir}
        fi
      '';
    };
  };
}
