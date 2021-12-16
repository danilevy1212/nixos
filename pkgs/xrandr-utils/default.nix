{ pkgs,... }: with pkgs; {
  horizontal = writeScriptBin "xcreen-horizontal-xps15" ''
    #!${stdenv.shell}

    exec ${xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1 --mode 1920x1080 --pos 1920x0 --rotate normal --output DP-2 --off --output DP-3 --off
  '';

  solo = writeScriptBin "xcreen-solo-xps15" ''
    #!${stdenv.shell}

    exec ${xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1 --off --output DP-2 --off --output DP-3 --off
  '';
}
