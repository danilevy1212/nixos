# Validate the specialArg `userConfig' and add it to the `config' set for other modules.
{
  lib,
  userConfig ? null,
  ...
}:
with lib;
assert assertMsg (isAttrs userConfig) "You must pass a `userConfig' attrSet to `home-manager.extraSpecialArgs'"; {
  options.userConfig = mkOption {
    description = "home-manager user configuration";
    default = userConfig;
    type = with types;
      submodule {
        options = {
          username = mkOption {
            type = str;
            example = "dlevym";
            description = "System username";
          };
          obsidianmd = mkOption {
            type = package;
            example = literalExpression "pkgs.obsidian";
            description = "Obsidian package until https://github.com/NixOS/nixpkgs/issues/273611 is fixed";
          };
        };
      };
  };
}
