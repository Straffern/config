{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.video;
in {
  options.${namespace}.suites.video = {
    enable = mkEnableOption "Video editing and recording suite";
  };

  config = mkIf cfg.enable {
    programs.obs-studio = enabled;

    home.packages = with pkgs; [
      audacity
      kdePackages.kdenlive
      davinci-resolve-studio
      webcamoid
    ];
  };
}
