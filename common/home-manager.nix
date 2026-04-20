{
  userConfig,
  ...
}: let
  username = userConfig.username;
in {
  # My user environment.
  home-manager = {
    # Home manager has access to system level dependencies.
    useGlobalPkgs = true;
    # Unclutter $HOME.
    useUserPackages = true;
    # Load my home-manager configuration.
    users."${username}" = import ./../home;
    # Easier debugging
    verbose = true;
    # In case of collision, use a .backup file.
    backupFileExtension = "backup";
  };
}
