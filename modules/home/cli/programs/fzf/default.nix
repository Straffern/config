{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption mkForce;
  cfg = config.${namespace}.cli.programs.fzf;
in {
  options.${namespace}.cli.programs.fzf = {
    enable = mkEnableOption "Whether or not to enable fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = with config.lib.stylix.colors.withHashtag;
        mkForce {
          "bg" = base00;
          "bg+" = base02;
          "fg" = base05;
          "fg+" = base05;
          "header" = base0E;
          "hl" = base08;
          "hl+" = base08;
          "info" = base0A;
          "marker" = base06;
          "pointer" = base06;
          "prompt" = base0E;
          "spinner" = base06;
        };
    };
  };
}
