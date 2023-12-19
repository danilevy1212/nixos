{
  inputs = {
    nixos-stable = {
      url = "github:nixos/nixpkgs/nixos-23.05";
    };
    nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    home-manager-unstable,
    darwin,
    ...
  }: let
    system = "x86_64-linux";
    nixpkgs-args = {
      inherit system;
      config.allowUnfree = true;
    };
    specialArgs = {
      unstable = import nixos-unstable nixpkgs-args;
      stable = import nixos-stable nixpkgs-args;
    };
    HOSTS = {
      dellXps15 = "dellXps15";
      nyx15v2 = "nyx15v2";
      inspirion = "inspirion";
    };
    addHostConfiguration = hostname: _:
      nixos-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager-unstable.nixosModules.home-manager
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
    nixosConfigurations = nixos-unstable.lib.attrsets.mapAttrs addHostConfiguration HOSTS;
    # TODO Deprecating soon
    darwinConfigurations = {
      autoMac = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          home-manager-unstable.darwinModules.home-manager
          ./hosts/autoMac
        ];
        inherit specialArgs;
      };
    };
    # TODO Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    #      See https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
  };
}
