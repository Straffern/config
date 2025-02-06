{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.yazi;
in {
  options.${namespace}.cli.programs.yazi = { enable = mkEnableOption "Yazi"; };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [
      imagemagick
      ffmpegthumbnailer
      fontpreview
      unar
      poppler
      unar
    ];
  };
}
