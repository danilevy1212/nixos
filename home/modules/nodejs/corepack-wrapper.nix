{
  pkgs,
  nodejs,
}:
pkgs.stdenv.mkDerivation {
  pname = "corepack-wrappers";
  inherit (nodejs) version;

  nativeBuildInputs = [nodejs];

  # No source needed
  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    corepack enable --install-directory $out/bin
  '';
}
