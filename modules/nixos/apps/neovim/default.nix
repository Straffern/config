{ options, config, pkgs, lib, ... }:
with lib;
with lib.custom;
let cfg = config.apps.neovim;
in {
  options.apps.neovim = with types; {
    enable = mkBoolOpt false "Enable or disable neovim";
  };

  config = mkIf cfg.enable {
    environment.variables = { EDITOR = "nvim"; };
    environment.systemPackages = with pkgs; [
      neovim
      ripgrep
      imagemagick
      luajitPackages.magick
      # pkgs.lazygit
      # pkgs.stylua
      # pkgs.sumneko-lua-language-server
    ];
    apps.tools.nix-ld.libraries = with pkgs; [
      imagemagick
      luajitPackages.magick
    ];

    home.persist.directories = [
      ".local/share/nvim"
      ".vim"
      # ".wakatime"
    ];

    # home.persist.files = [".wakatime.cfg" ".wakatime.bdb"];
  };
}
