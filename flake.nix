{
  inputs = {
    # Latest stable release of nixos
    nixos-stable = {
      url = "github:nixos/nixpkgs/nixos-25.11";
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
    # Hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    # Declarative flatpaks
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
    # Up-to-date AI tools, for nix
    llm-agents.url = "github:numtide/llm-agents.nix";
    # nix-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # nixpkgs-stable
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    };
    # nixpkgs-unstable
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    nix-darwin,
    nixpkgs-stable,
    nixpkgs-unstable,
    home-manager-unstable,
    nixos-hardware,
    colortest,
    flatpaks,
    llm-agents,
    ...
  }: let
    # Helper to clean up package instantiation
    mkPkgs = pkgsInput: sys:
      import pkgsInput {
        system = sys;
        config.allowUnfree = true;
      };

    # Instantiations
    stable = mkPkgs nixos-stable "x86_64-linux";
    unstable = mkPkgs nixos-unstable "x86_64-linux";
    stable-darwin = mkPkgs nixpkgs-stable "aarch64-darwin";
    unstable-darwin = mkPkgs nixpkgs-unstable "aarch64-darwin";

    # Home-manager configuration.
    defaultHomeManagerUserConfig = {
      username = "dlevym";
      isWork = false;
      modules = {
        neovim = {enable = true;};
        gui = {enable = true;};
        python = {enable = true;};
        nodejs = {enable = true;};
        golang = {enable = true;};
        rust = {enable = true;};
        cli = {
          enable = true;
          agents.enable = true;
          git = {
            userEmail = "daniellevymoreno@gmail.com";
          };
        };
      };
    };

    lib = nixos-unstable.lib;

    # Helper to merge userConfig easily
    mkSpecialArgs = stablePkgs: unstablePkgs: customUserConfig: {
      stable = stablePkgs;
      unstable = unstablePkgs;
      userConfig = lib.recursiveUpdate defaultHomeManagerUserConfig customUserConfig;
    };

    defaultSpecialArgsLinux = mkSpecialArgs stable unstable {};

    addHostConfiguration = sys: hostname: additionalModules: specialArgs:
      nixos-unstable.lib.nixosSystem {
        system = sys;
        inherit specialArgs;
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
                colortest.packages."${sys}".colortest
              ];
              networking.hostName = hostname;
              home-manager.extraSpecialArgs = specialArgs;
              # Common NIX_PATH, by default we are on unstable
              nix.nixPath = [
                "nixpkgs=${nixos-unstable}"
              ];
              # llm-agents tends to be more up-to-date
              nixpkgs.config.packageOverrides = pkgs: {
                opencode = llm-agents.packages."${sys}".opencode;
              };
            }
          ]
          ++ nixos-unstable.lib.optionals (builtins.isList additionalModules) additionalModules;
      };
  in {
    # Refactor to use flake-parts or flake-utils
    nixosConfigurations = {
      nyx15v2 = addHostConfiguration "x86_64-linux" "nyx15v2" [] defaultSpecialArgsLinux;
      bootse = addHostConfiguration "x86_64-linux" "bootse" [] defaultSpecialArgsLinux;
      zflow13 = addHostConfiguration "x86_64-linux" "zflow13" [] defaultSpecialArgsLinux;
      thinkpadP14s =
        addHostConfiguration "x86_64-linux" "thinkpadP14s" [
          {
            imports = [
              # add your model from this list: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
              nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5
            ];
          }
        ]
        (mkSpecialArgs stable unstable {
          username = "daniel-moreno-levy";
          isWork = true;
          modules.cli.git.userEmail = "daniel.moreno.levy@gravwell.io";
        });
    };
    darwinConfigurations."Daniels-MacBook-Pro" = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      specialArgs = mkSpecialArgs stable-darwin unstable-darwin {
        username = "daniel.moreno.levy";
        isWork = true;
        modules.cli.git.userEmail = "daniel.moreno.levy@gravwell.io";
      };
      modules = [
        home-manager-unstable.darwinModules.home-manager
        ./hosts/Daniels-MacBook-Pro
        {
          # Re-allow unfree packages for the core nix-darwin system
          nixpkgs.config.allowUnfree = true;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
    # Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    homeConfigurations."generic" = home-manager-unstable.lib.homeManagerConfiguration {
      pkgs = unstable;
      extraSpecialArgs = defaultSpecialArgsLinux;

      # Make sure to allow unfree packages
      nixpkgs = {
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };

      modules = [
        ./home
      ];
    };
  };
}
