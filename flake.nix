{
  inputs = {
    # Latest stable release of nixos
    nixos-stable = {
      url = "github:nixos/nixpkgs/nixos-23.11";
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
    # AWS VPN Client
    awsvpnclient.url = "github:ymatsiuk/awsvpnclient";
    # Colortest, for testing terminal colors
    colortest = {
      url = "./pkgs/colortest";
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
        cli = {
          enable = true;
          git = {
            userEmail = "daniellevymoreno@gmail.com";
            gh = {
              extraExtensions = [
                gh-copilot.packages."${system}".gh-copilot
              ];
            };
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
    addHostConfiguration = hostname: additionalModules:
      nixos-unstable.lib.nixosSystem {
        inherit system;
        modules =
          [
            home-manager-unstable.nixosModules.home-manager
            ./hosts/${hostname}
            ./common
            {
              environment.systemPackages = [
                # Colortest, for testing terminal colors
                colortest.packages."${system}".colortest
              ];
              networking.hostName = hostname;
              home-manager.extraSpecialArgs = defaultSpecialArgs;
            }
          ]
          ++ nixos-unstable.lib.optionals (builtins.isList additionalModules) additionalModules;
        specialArgs = defaultSpecialArgs;
      };
  in {
    # Refactor to use flake-parts or flake-utils
    nixosConfigurations = {
      dellXps15 = addHostConfiguration "dellXps15" [];
      nyx15v2 = addHostConfiguration "nyx15v2" [];
      inspirion = addHostConfiguration "inspirion" [
        {
          environment.systemPackages = [
            # AWS VPN Client
            awsvpnclient.packages."${system}".awsvpnclient
          ];
          # NOTE  Through `userConfig`, we can configure the home-manager modules.
          home-manager.extraSpecialArgs = mergeWithDefaultSpecialArgs {
            userConfig.modules = {
              cli.git.userEmail = "dalevy@autopay.com";
              rust.enable = false;
              networking.work = true;
            };
          };
        }
      ];
      bootse = addHostConfiguration "bootse" [];
    };
    # TODO Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    #      See https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
  };
}
