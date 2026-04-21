{
  description = "A flake for the colortest package";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = forAllSystems (system: {
      colortest = (pkgsFor system).stdenv.mkDerivation {
        name = "colortest";
        src = ./.;
        buildPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          chmod +x ./colortest.sh
          mv ./colortest.sh $out/bin/colortest
        '';
      };
      default = self.packages.${system}.colortest;
    });
  };
}
