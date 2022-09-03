{pkgs, ...}:
with pkgs;
  stdenv.mkDerivation {
    pname = "Quivera";
    version = "0.0.1";
    src = fetchurl {
      url = "http://www.quivira-font.com/files/Quivira.ttf";
      sha256 = "0z2vh58g9x7gji31mwg1gz5gs1r9rf4s9wyiw92dc7xyvibai6dv";
    };
    sourceRoot = "./";
    unpackCmd = ''
      ttfName=$(basename $(stripHash $curSrc))
      cp $curSrc ./$ttfName
    '';
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -a *.ttf $out/share/fonts/truetype/
    '';
  }
