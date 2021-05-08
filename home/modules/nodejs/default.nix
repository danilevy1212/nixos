{ config, lib, pkgs, environment, ... }: {
  home.packages = with pkgs; [ nodejs-14_x yarn ];

  # Move NPM Configuration from $HOME.
  home = {
    sessionVariables = {
      NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
      NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
      NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      NPM_CONFIG_PREFIX = "$XDG_CACHE_HOME/npm";
      NODE_REPL_HISTORY = "$XDG_CACHE_HOME/node/repl_history";
    };
  };

  # Global packages readily usable.
  programs.zsh = {
    envExtra = ''
      export PATH="$PATH:$XDG_CACHE_HOME/npm/bin"
    '';
  };
}
