{
  config,
  userConfig,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should manage.
  home = rec {
    username = userConfig.username;
    homeDirectory = "/home/${username}";
    stateVersion = config.home.version.release;
  };
}
