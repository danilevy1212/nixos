{
  inputs = {
    nixpkgs = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-23.05";
    };
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
    nixpkgs-stable,
    nixpkgs-unstable,
    home-manager,
    darwin,
    emacs-overlay,
    ...
  }: let
    system = "x86_64-linux";
    nixpkgs-args = {
      inherit system;
      config.allowUnfree = true;
    };
    specialArgs = {
      emacs-overlay = emacs-overlay.overlay;
      unstable = import nixpkgs-unstable nixpkgs-args;
      stable = import nixpkgs-stable nixpkgs-args;
    };
    HOSTS = {
      dellXps15 = "dellXps15";
      nyx15v2 = "nyx15v2";
      inspirion = "inspirion";
    };
    addHostConfiguration = hostname: _:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/${hostname}
        ];
        specialArgs =
          specialArgs
          // {
            inherit hostname;
            inherit HOSTS;
          };
      };
  in {
    # NOTE https://teu5us.github.io/nix-lib.html#lib.attrsets.mapattrs
    nixosConfigurations = nixpkgs.lib.attrsets.mapAttrs addHostConfiguration HOSTS;
    # TODO Deprecating soon
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
