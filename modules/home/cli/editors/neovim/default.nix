{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.editors.neovim;
  stylixEnabled = config.${namespace}.styles.stylix.enable;
in {
  options.${namespace}.cli.editors.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      # extraLuaPackages = ps: [ ps.luarocks ps.magick ];
      extraPackages = [
        pkgs.imagemagick
        pkgs.ripgrep
        pkgs.zig
        pkgs.gnumake
        pkgs.cargo
        pkgs.nodejs-slim
      ];

      extraLuaConfig = ''
        -- bootstrap lazy.nvim, LazyVim and your plugins
        require("config.lazy")
      '';

      # TODO: add following symlink, when everything works
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    stylix.targets.neovim = mkIf stylixEnabled { enable = false; };

    # maybe make it a symlink outside nix store?
    # In order to work, mkOutOfStoreSymlink needs full absolute path to file on disk:
    # https://github.com/nix-community/home-manager/issues/676#issuecomment-1595795685
    # https://github.com/ncfavier/config/blob/954cbf4f569abe13eab456301a00560d82bd0165/modules/nix.nix#L12-L14
    xdg.configFile."nvim/lua" = {
      enable = true;
      recursive = true;
      source = ./lazyvim;
    };
  };
}
