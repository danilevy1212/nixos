{ config, lib, pkgs, nixos ? import <nixos>, ... }: {
  # TODO I shall replace you with rclone and gdrive soon!
  services.dropbox = {
    enable = true;
    path = "${config.home.homeDirectory}/Cloud";
  };

  home.packages = with pkgs; [
    awscli
    kubectl
    krew
    telepresence2
    kubernetes-helm-wrapped
    rclone
    keepassxc
  ];

  # Passwords
  services.keepassx.enable = true;

  home.sessionVariables = {
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
  };

  # Global packages readily usable.
  home.sessionPath = [
    "$HOME/.krew/bin"
  ];

  # Add an alias for kubectl
  programs.zsh.shellAliases = { k = "kubectl"; };
}
