{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
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
        pkgs.deno # required by peek.nvim
        pkgs.imagemagick
        pkgs.ripgrep
        pkgs.zig
        pkgs.gnumake
        pkgs.cargo
        pkgs.nodejs_24
        pkgs.tree-sitter
      ];

      initLua = ''
        -- bootstrap lazy.nvim, LazyVim and your plugins
        require("config.lazy")
      '';

      # TODO: add following symlink, when everything works
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    stylix.targets.neovim = mkIf stylixEnabled {enable = false;};

    xdg.configFile."nvim/lua" = {
      enable = true;
      recursive = true;
      source = config.lib.asgaard.managedSource ./lazyvim;
    };

    ${namespace}.system.persistence.directories = [".local/share/nvim" ".local/state/nvim"];
  };
}
