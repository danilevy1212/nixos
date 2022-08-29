{ pkgs, }:

let
  pname = "colortest";
in
pkgs.stdenv.mkDerivation {
  name = pname;
  src = ./.;

  installPhase =
    ''
      mkdir -p $out/bin
      mv ./colortest.sh $out/bin/colortest
    '';
}
