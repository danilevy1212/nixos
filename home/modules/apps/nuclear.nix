{
  fetchurl,
  appimageTools,
  ...
}: let
  pname = "nuclear";
  version = "eac584";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "https://github.com/nukeop/nuclear/releases/download/${version}/${name}.AppImage";
    sha256 = "16jvp41c1ajb0smiq2zban9d49vdcgc6ik3xnqfa7msig06ias4p";
  };

  appimageContents = appimageTools.extract {inherit name src;};
in
  appimageTools.wrapType2 {
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';
  }
