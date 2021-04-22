{ config, lib, pkgs, ... }: {
  # TODO I shall replace you with rclone and gdrive soon!
  services.dropbox = {
    enable = true;
    path = "${config.home.homeDirectory}/Cloud";
  };

  home.packages = with pkgs; [ awscli kubectl krew ];

  home.sessionVariables = {
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    PATH = "$PATH:$HOME/.krew/bin";
  };

  # Add an alias for kubectl
  programs.zsh.shellAliases = { k = "kubectl"; };
}
