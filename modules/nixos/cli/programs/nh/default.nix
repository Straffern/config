{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.cli.programs.nh;
in {
  options.cli.programs.nh = { enable = mkEnableOption "nh"; };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.user.name}/dotfiles";
    };
  };
}
