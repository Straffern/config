{ options, config, pkgs, lib, namespace, ... }:
with lib;
with lib.custom;
let cfg = config.${namespace}.apps.neovim;
in {
  options.${namespace}.apps.neovim = with types; {
    enable = mkBoolOpt false "Enable or disable neovim";
  };

  config = mkIf cfg.enable {
    environment.variables = { EDITOR = "nvim"; };
    environment.systemPackages = with pkgs; [
      neovim
      ripgrep
      imagemagick
      luajitPackages.magick

      luajitPackages.luarocks
      # pkgs.lazygit
      # pkgs.stylua
      # pkgs.sumneko-lua-language-server
    ];
    apps.tools.nix-ld.libraries = with pkgs; [
      imagemagick
      luajitPackages.magick
      luajitPackages.luarocks
    ];

    home.persist.directories = [
      ".local/share/nvim"
      ".vim"
      # ".wakatime"
    ];

    # home.persist.files = [".wakatime.cfg" ".wakatime.bdb"];
  };
}
