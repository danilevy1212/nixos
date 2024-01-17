{
  description = "A flake for the colortest package";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages.x86_64-linux.colortest = nixpkgs.legacyPackages.x86_64-linux.callPackage ./colortest.nix {pkgs = nixpkgs;};
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.colortest;
  };
}
