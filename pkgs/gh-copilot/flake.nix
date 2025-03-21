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
      packages = let
        version = "v1.0.5";
      in rec {
        gh-copilot = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation {
          inherit version;
          pname = "gh-copilot";
          src = nixpkgs.legacyPackages.${system}.fetchurl {
            url = "https://github.com/github/gh-copilot/releases/download/${version}/linux-amd64";
            sha256 = "sha256-u9/4q0dA3ixxv3j8u3eZKf3w2iYJjpYJIALLto9+290=";
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
