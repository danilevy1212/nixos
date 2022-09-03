{
  inputs = {
    nixpkgs = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixpkgs-unstable";};
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {url = "github:nix-community/emacs-overlay";};
  };
  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    darwin,
    emacs-overlay,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    specialArgs = {
      emacs-overlay = emacs-overlay.overlay;
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      dellXps15 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/dellXps15
        ];
        inherit specialArgs;
      };
      nyx15v2 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/nyx15v2
        ];
        inherit specialArgs;
      };
    };
    darwinConfigurations = {
      autoMac = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/autoMac
        ];
        inherit specialArgs;
      };
    };
  };
}
