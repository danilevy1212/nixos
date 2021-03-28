{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # TODO Look into mopidy instead
    # Proprietary musicality
    spotify

    # Social closeness
    rambox # TODO Contrast with https://getferdi.com/
    skype

    # Browser for the...
    brave
  ];
}
