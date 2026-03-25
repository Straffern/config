{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.${namespace}.cli.programs.fzf;
  dmsEnabled = config.programs.dank-material-shell.enable;
  dmsFzfTemplate = pkgs.writeText "dms-fzf-template" (builtins.readFile ./dms-theme.txt);
  dmsFzfBootstrap = pkgs.writeText "dms-fzf-bootstrap" "";
in {
  options.${namespace}.cli.programs.fzf = {
    enable = mkEnableOption "Whether or not to enable fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = mkIf (!dmsEnabled) (
        with config.lib.stylix.colors.withHashtag;
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
          }
      );
    };

    xdg.configFile."matugen/dms/configs/fzf.toml" = mkIf dmsEnabled {
      text = ''
        [templates.dmsfzf]
        input_path = '${dmsFzfTemplate}'
        output_path = '${config.xdg.configHome}/fzf/dank-theme'
      '';
    };

    home.sessionVariables = mkIf dmsEnabled {
      FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/dank-theme";
    };

    home.activation.dmsFzfBootstrap = mkIf dmsEnabled {
      after = ["writeBoundary"];
      before = [];
      data = ''
        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/fzf/dank-theme"} ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
            ${lib.escapeShellArg "${dmsFzfBootstrap}"} \
            ${lib.escapeShellArg "${config.xdg.configHome}/fzf/dank-theme"}
        fi
      '';
    };
  };
}
