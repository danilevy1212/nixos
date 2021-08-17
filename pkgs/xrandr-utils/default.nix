with import <nixpkgs> { }; {
  horizontal = pkgs.writeScriptBin "xcreen-horizontal-xps15" ''
    #!${stdenv.shell}

    exec ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1 --mode 1920x1080 --pos 1920x0 --rotate normal --output DP-2 --off --output DP-3 --mode 1920x1080 --pos 3840x0 --rotate normal
  '';

   solo = pkgs.writeScriptBin "xcreen-solo-xps15" ''
    #!${stdenv.shell}

    exec ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1 --off --output DP-2 --off
  '';
}
