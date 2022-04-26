{
  fetchurl,
  appimageTools,
  ...
}: let
  pname = "nuclear";
  version = "f5ec0d";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "https://github.com/nukeop/nuclear/releases/download/${version}/${name}.AppImage";
    sha256 = "0x8348di2hx2dc01plk55wrcnkyll1ak6hnlj3n537k8ymhfpswy";
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
