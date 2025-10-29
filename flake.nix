{
  inputs = {
    # Latest stable release of nixos
    nixos-stable = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    # Rolling release of nixos
    nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    # Rolling release of home-manager
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    # Colortest, for testing terminal colors
    colortest = {
      url = "./pkgs/colortest";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    # Latest version with plasma that works with HDR + sunshine
    nixos-plasma = {
      url = "github:nixos/nixpkgs/8d5bdaf3a45a6e42a23ff476ba478731752c7f95";
    };
    # Hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    # Declarative flatpaks
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    home-manager-unstable,
    nixos-hardware,
    colortest,
    flatpaks,
    ...
  }: let
    system = "x86_64-linux";
    stable = import nixos-stable nixpkgs-args;
    unstable = import nixos-unstable nixpkgs-args;
    nixpkgs-args = {
      inherit system;
      config.allowUnfree = true;
    };
    # Home-manager configuration.
    defaultHomeManagerUserConfig = {
      username = "dlevym";
      modules = {
        neovim = {
          enable = true;
        };
        gui = {
          enable = true;
        };
        python = {
          enable = true;
        };
        nodejs = {
          enable = true;
        };
        golang = {
          enable = true;
        };
        rust = {
          enable = true;
        };
        cli = {
          enable = true;
          git = {
            userEmail = "daniellevymoreno@gmail.com";
          };
        };
      };
    };
    defaultSpecialArgs = {
      inherit stable;
      inherit unstable;
      userConfig = defaultHomeManagerUserConfig;
    };
    mergeWithDefaultSpecialArgs = customConfig: nixos-unstable.lib.attrsets.recursiveUpdate defaultSpecialArgs customConfig;
    addHostConfiguration = hostname: additionalModules: specialArgs:
      nixos-unstable.lib.nixosSystem {
        inherit system specialArgs;
        modules =
          [
            home-manager-unstable.nixosModules.home-manager
            ./hosts/${hostname}
            ./common
            ./cachix.nix
            {
              # Declarative flatpaks
              imports = [
                flatpaks.nixosModules.default
              ];
              # Colortest, for testing terminal colors
              environment.systemPackages = [
                colortest.packages."${system}".colortest
              ];
              networking.hostName = hostname;
              home-manager.extraSpecialArgs = specialArgs;
              # Common NIX_PATH, by default we are on unstable
              nix.nixPath = [
                "nixpkgs=${nixos-unstable}"
              ];
            }
          ]
          ++ nixos-unstable.lib.optionals (builtins.isList additionalModules) additionalModules;
      };
  in {
    imports = [
      ./cachix.nix
    ];
    # Refactor to use flake-parts or flake-utils
    nixosConfigurations = {
      nyx15v2 = addHostConfiguration "nyx15v2" [] defaultSpecialArgs;
      bootse = addHostConfiguration "bootse" [] defaultSpecialArgs;
      zflow13 = addHostConfiguration "zflow13" [] defaultSpecialArgs;
      thinkpadP14s =
        addHostConfiguration "thinkpadP14s" [
          {
            imports = [
              # add your model from this list: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
              nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5
            ];
          }
        ]
        (mergeWithDefaultSpecialArgs {
          userConfig = {
            username = "daniel-moreno-levy";
            modules = {
              cli.git.userEmail = "daniel.moreno.levy@gravwell.io";
            };
          };
        });
    };
    # TODO Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    #      See https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
  };
}
