{
  inputs,
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.roles.video;
in {
  options.${namespace}.roles.video = {
    enable = mkEnableOption "Video editting and recording suite";
  };

  config = mkIf cfg.enable {
    xdg.configFile."obs-studio/themes".source = "${inputs.catppuccin-obs}/themes";

    programs.obs-studio = enabled;

    home.packages = with pkgs; [
      audacity
      kdePackages.kdenlive
      davinci-resolve-studio
    ];
  };
}
