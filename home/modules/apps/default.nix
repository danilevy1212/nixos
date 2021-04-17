{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # TODO Look into mopidy instead
    # Proprietary musicality
    spotify

    # Social closeness
    rambox # TODO Contrast with https://getferdi.com/
    skype
    tdesktop

    # Browser for the...
    brave

    # video player
    mpv-with-scripts
  ];
}
