{
  pkgs,
  lib,
  config,
  ...
}: let
  ipythonDir = "${config.xdg.configHome}/ipython";
in {
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
}
