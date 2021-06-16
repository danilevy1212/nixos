{ config, lib, pkgs, environment, ... }: {
  home.packages = with pkgs; [ nodejs yarn ];

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

  programs.zsh = {
    shellAliases = {
      yarn = "yarn --use-yarnrc $XDG_CONFIG_HOME/yarn/config";
    };
  };

  # Global packages readily usable.
  home.sessionPath = [
    "$XDG_CACHE_HOME/npm/bin"
  ];
}
