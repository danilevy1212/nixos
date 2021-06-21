let
  pyVer = "python39";
  pkgs = import <nixos> { };
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "refs/tags/3.3.0";
  }) rec { python = pyVer; };
  xonsh39 = pkgs.xonsh.override { python3Packages = pkgs.python39Packages; };
  xonshDep = mach-nix.mkPython {
    requirements = ''
      # Theme
      nord-pygments # TODO Patch to remove pygments

      # Xontribs
      jedi
      xontrib-argcomplete
      xontrib-z
      xontrib-sh
      # xontrib-pipeliner # TODO TRY TO PATCH IT, remove xonsh dependency
      xontrib-fzf-widgets
      xontrib-readable-traceback
      # xontrib-prompt-starship TODO Maybe overkill

      # bunch of other requirements
      requests
    '';

    # _.xontrib-pipeliner.patches [ TODO Remove xonsh from requirements.txt ] # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/window-managers/qtile/0001-Substitution-vars-for-absolute-paths.patch
    providers = {
      pygments = "nixpkgs";
      # xontrib-pipeliner = "sdist";
    };
  };

in {
  xonsh = with pkgs;
    # TODO With pygments patch, just use old.propagatedBuildInputs
    xonsh39.overrideAttrs (old: {
      propagatedBuildInputs = with python39Packages;
        [ ply prompt_toolkit ] ++ [ xonshDep ];
    });
}
