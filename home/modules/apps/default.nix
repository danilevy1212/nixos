{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # TODO Look into mopidy instead
    # Proprietary musicality
    spotify

    # Social closeness
    ferdi
    skype

    # Browser for the...
    brave

    # video player
    mpv-with-scripts
  ];
}
