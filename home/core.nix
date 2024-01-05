{config, ...}: let
  cfg = config.userConfig;
in {
  imports = [
    ./userConfig.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home = rec {
    username = cfg.username;
    homeDirectory = "/home/${username}";
    stateVersion = config.home.version.release;
  };
}
