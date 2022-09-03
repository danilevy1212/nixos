{
  config,
  lib,
  pkgs,
  ...
}: {
  # TODO I shall replace you with rclone and gdrive soon!
  services.dropbox = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    path = "${config.home.homeDirectory}/Cloud";
  };
  # For MacOS, we just link the Dropbox folder to Cloud
  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    linkDropboxWithCloud = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -L ${config.home.homeDirectory}/Cloud ] && [ -d ${config.home.homeDirectory}/Dropbox ]
      then
      $DRY_RUN_CMD ln -s $VERBOSE_ARG \
          ${config.home.homeDirectory}/Dropbox ${config.home.homeDirectory}/Cloud
      fi
    '';
  };

  # Work stuff
  home.packages = with pkgs; [
    awscli2
    rclone
  ];

  home.sessionVariables = {
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    AWS_PROFILE = "autopay-developer";
  };
}
