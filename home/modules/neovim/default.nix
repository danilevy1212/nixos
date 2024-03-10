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
        luajitPackages.luarocks

        # For nix
        alejandra

        # For tree-sitter
        zig
        gcc
        tree-sitter

        # For telescope fzf
        gnumake

        # For mason
        ## languages
        ## rust
        stable.cargo
      ]
      # GUI for neovim
      ++ lib.optional userConfig.modules.gui.enable neovide;

    # Basic settings for neovim + terminal integration
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimdiffAlias = true;
      vimAlias = true;
      # For CopilotChat
      extraPython3Packages = ps:
        with ps; [
          pynvim
          prompt-toolkit
          tiktoken
          python-dotenv
          requests
        ];
    };

    # "auto" install nvim
    home.activation = {
      # I should probably make it an option somewhere to either use ssh or https.
      nvim-install = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d ${nvim_config_dir} ]
        then
           $DRY_RUN_CMD ${pkgs.gitAndTools.gitFull}/bin/git clone git@github.com:danilevy1212/nvim.git ${nvim_config_dir}
        fi
      '';
    };
  };
}
