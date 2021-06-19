let
  pyVer = "python39";
  pkgs = import <nixos> {};
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "refs/tags/3.3.0";
  }) rec {
    python = pyVer;
  };
  xonsh39 = pkgs.xonsh.override { python3Packages = pkgs.python39Packages; };
  xonshDep = mach-nix.mkPython {

  requirements = ''
    # Theme
    nord-pygments

    # Xontribs

    # bunch of other requirements
    requests
  '';
};
in {
  xonsh = xonsh39.overrideAttrs (old: {
    propagatedBuildInputs = with pkgs.python39Packages; [ ply prompt_toolkit ] ++ [ xonshDep ];
  });
}
