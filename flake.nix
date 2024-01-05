{
  inputs = {
    # Latest stable release of nixpkgs
    nixos-stable = {
      url = "github:nixos/nixpkgs/nixos-23.11";
    };
    # Rolling release of nixpkgs
    nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    # Nightly release of nixpkgs
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    # Rolling release of home-manager
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    home-manager-unstable,
    ...
  }: let
    system = "x86_64-linux";
    stable = import nixos-stable nixpkgs-args;
    unstable = import nixos-unstable nixpkgs-args;
    # ISSUE  https://github.com/NixOS/nixpkgs/issues/273611
    obsidianmd = let
      lib = unstable.lib;
      obsidianVersion = unstable.pkgs.obsidian.version;
    in
      # NOTE  We are creating a special deriviation that will be used to build `obsidianmd`, so we don't pollute the
      #       `nixos-unstable` derivation with `electron-25.9.0` which is only needed for `obsidianmd`.
      #       When the issue is solved, we can remove this and get `obsidianmd` from `nixos-unstable` directly.
      with lib;
        (import nixos-unstable (
          # NOTE https://discourse.nixos.org/t/how-to-permit-insecure-package-as-input-to-another-package/19960/4
          lib.recursiveUpdate {
            config.permittedInsecurePackages =
              throwIf (versionOlder "1.5.3" obsidianVersion) "Obsidian no longer requires EOL Electron"
              ["electron-25.9.0"];
          }
          nixpkgs-args
        ))
        .obsidian;
    nixpkgs-args = {
      inherit system;
      config.allowUnfree = true;
    };
    # Home-manager configuration.
    userConfig = {
      username = "dlevym";
      inherit obsidianmd;
    };
    specialArgs = {
      inherit stable;
      inherit unstable;
      inherit userConfig;
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
    # TODO Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    #      See https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
  };
}
