{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.userConfig.modules.nodejs;
in {
  options = {
    userConfig.modules.nodejs = {
      enable = mkEnableOption "Node.js support";
    };
  };
  config = lib.mkIf cfg.enable {
    # Move NPM Configuration from $HOME.
    home = {
      sessionVariables = {
        NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
        NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
        NPM_CONFIG_PREFIX = "$XDG_CACHE_HOME/npm";
        NODE_REPL_HISTORY = "$XDG_CACHE_HOME/node/repl_history";

        # YARN
        COREPACK_HOME = "$XDG_CACHE_HOME/corepack";

        # FNM, auto-enable corepack
        FNM_COREPACK_ENABLED = "true";
      };
      # Global packages readily usable.
      sessionPath = [
        "$XDG_CACHE_HOME/npm/bin"
      ];

      # Node
      packages = with pkgs; [
        # Node version manager
        fnm
        nodejs
      ];
    };
  };
}
