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
    # AWS VPN Client
    awsvpnclient.url = "github:ymatsiuk/awsvpnclient";
    # Colortest, for testing terminal colors
    colortest = {
      # NOTE Use this for testing local changes, see https://github.com/NixOS/nix/issues/3978
      url = "./pkgs/colortest";
      # NOTE  This URL has the limitation that it can only import commited changes, so it's not useful for testing
      # See https://discourse.nixos.org/t/flakes-re-locking-necessary-at-each-evaluation-when-import-sub-flake-by-path/34465/11
      # url = "git+file:./?dir=pkgs/colortest";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    # gh-copilot
    gh-copilot = {
      url = "./pkgs/gh-copilot";
      inputs.nixpkgs.follows = "nixos-stable";
    };
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    home-manager-unstable,
    awsvpnclient,
    colortest,
    gh-copilot,
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
      gh-extensions = [gh-copilot.packages."${system}".gh-copilot];
    };
    specialArgs = {
      inherit stable;
      inherit unstable;
      inherit userConfig;
      inherit colortest;
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
          {
            environment.systemPackages = [
              # AWS VPN Client, for work
              awsvpnclient.packages."${system}".awsvpnclient
              # Colortest, for testing terminal colors
              colortest.packages."${system}".colortest
            ];
          }
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
