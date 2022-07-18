{
  config,
  lib,
  pkgs,
  environment,
  ...
}: {
  home.packages = with pkgs; [
    nodejs
    (import ./corepack-wrapper.nix {
      inherit pkgs;
      inherit nodejs;
    })
  ];

  # Move NPM Configuration from $HOME.
  home = {
    sessionVariables = {
      NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
      NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
      NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      # NOTE: Not compatible with nvm
      # NPM_CONFIG_PREFIX = "$XDG_CACHE_HOME/npm";
      NODE_REPL_HISTORY = "$XDG_CACHE_HOME/node/repl_history";

      # YARN
      COREPACK_HOME = "$XDG_CACHE_HOME/corepack";
    };
  };

  # Global packages readily usable.
  home.sessionPath = [
    "$XDG_CACHE_HOME/npm/bin"
  ];
}
