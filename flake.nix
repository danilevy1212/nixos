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
    # AWS VPN Client
    awsvpnclient = {
      url = "github:ymatsiuk/awsvpnclient/56ca114e3f7fe4db9d745a0ab8ed70c6bd803a8f";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
  };
  outputs = {
    nixos-stable,
    nixos-unstable,
    nixos-plasma,
    home-manager-unstable,
    awsvpnclient,
    colortest,
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
      work = false;
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
    addHostConfiguration = hostname: additionalModules:
      nixos-unstable.lib.nixosSystem {
        inherit system;
        modules =
          [
            home-manager-unstable.nixosModules.home-manager
            ./hosts/${hostname}
            ./common
            ./cachix.nix
            {
              environment.systemPackages = [
                # Colortest, for testing terminal colors
                colortest.packages."${system}".colortest
              ];
              networking.hostName = hostname;
              home-manager.extraSpecialArgs = nixos-unstable.lib.mkDefault defaultSpecialArgs;
            }
            {
              # Common NIX_PATH, by default we are on unstable
              nix.nixPath = [
                "nixpkgs=${nixos-unstable}"
              ];
            }
          ]
          ++ nixos-unstable.lib.optionals (builtins.isList additionalModules) additionalModules;
        specialArgs = defaultSpecialArgs;
      };
  in {
    imports = [
      ./cachix.nix
    ];
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
          home-manager.extraSpecialArgs = nixos-unstable.lib.mkForce (mergeWithDefaultSpecialArgs {
            userConfig = {
              work = true;
              modules = {
                cli.git.userEmail = "dalevy@autopay.com";
                rust.enable = false;
              };
            };
          });
        }
      ];
      bootse = addHostConfiguration "bootse" [
        {
          home-manager.extraSpecialArgs = defaultSpecialArgs;
          # NOTE  Leaving this commented, 6.4 + https://github.com/LizardByte/Sunshine/issues/3298#issuecomment-2726581996 seems to work
          #       but it could break at any time
          # HACK  Unfortunately, version of plasma > 6.2.0 breaks my sunshine HDR setup
          #       see https://github.com/LizardByte/Sunshine/issues/3298
          #       see https://github.com/LizardByte/Sunshine/issues/3327
          #       Until these are resolved, we need to pin 6.2.0 on the system.
          # nixpkgs.overlays = let
          #   plasma-pinned-pkgs = import nixos-plasma nixpkgs-args;
          #   pkgs = import nixos-unstable nixpkgs-args;
          # in [
          #   (self: super:
          #     with plasma-pinned-pkgs; {
          #       kdePackages =
          #         {
          #           aurorae = pkgs.kdePackages.aurorae;
          #           kwin-x11 = pkgs.kdePackages.kwin-x11;
          #           ksystemstats = pkgs.kdePackages.ksystemstats;
          #         }
          #         // kdePackages;
          #       # NOTE  Prevent firefox issues by using the same firefox as the KDE version
          #       firefox = firefox;
          #     })
          # ];
          # # HACK  I really need to move out of this KDE version
          # security.wrappers = {
          #   ksystemstats_intel_helper = nixos-unstable.lib.mkForce {
          #     enable = false;
          #   };
          # };
        }
      ];
    };
    # TODO Have a configuration that is only `home-manager`, meant for systems that may or may not be `NIXOS`
    #      See https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
  };
}
