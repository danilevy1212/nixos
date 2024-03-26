{
  description = "A flake for GitHub Copilot CLI";

  # Define inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Define outputs
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = rec {
        gh-copilot = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation {
          pname = "gh-copilot";
          version = "v1.0.1";
          src = nixpkgs.legacyPackages.${system}.fetchurl {
            url = "https://github.com/github/gh-copilot/releases/download/v1.0.1/linux-amd64";
            sha256 = "sha256-vEmMxvadVkXawDGGb8el2VT2IPtWFTPRPbi7tGs/NAY=";
            executable = true;
          };

          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            install -D $src $out/bin/gh-copilot
          '';

          meta = with nixpkgs.legacyPackages.${system}.lib; {
            description = "GitHub Copilot CLI";
            homepage = "https://github.com/github/gh-copilot";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };
        default = gh-copilot;
      };
    });
}
