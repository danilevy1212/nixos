{
  pkgs,
  lib,
  stable,
  userConfig,
  config,
  ...
}:
with lib; let
  cfg = config.userConfig.modules.neovim;
  nvim_config_dir = "${config.xdg.configHome}/nvim";
in {
  options.userConfig.modules.neovim = {
    enable = mkEnableOption "neovim";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        # For lazyvim
        luajitPackages.luarocks
        lua5_1

        # For nix
        alejandra

        # For tree-sitter
        zig
        gcc
        tree-sitter

        # For telescope fzf
        gnumake

        # Nix language server
        nixd
      ]
      # For mason
      ## languages
      ## rust
      ++ lib.optional (!userConfig.modules.rust.enable) cargo
      # GUI for neovim
      ++ lib.optional userConfig.modules.gui.enable neovide;

    # Basic settings for neovim + terminal integration
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimdiffAlias = true;
      vimAlias = true;
    };

    # "auto" install nvim
    home.activation = {
      nvim-install = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d ${nvim_config_dir} ]
        then
           $DRY_RUN_CMD ${pkgs.gitFull}/bin/git clone https://github.com/danilevy1212/nvim.git ${nvim_config_dir}
           $DRY_RUN_CMD ${pkgs.gitFull}/bin/git remote set-url origin git@github.com:danilevy1212/nvim.git
        fi
      '';
    };
  };
}
