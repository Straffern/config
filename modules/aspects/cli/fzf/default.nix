{den, ...}: {
  den.aspects.cli.fzf.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    dmsEnabled = config.programs ? dank-material-shell && config.programs.dank-material-shell.enable;
    template = pkgs.writeText "dms-fzf-template" (builtins.readFile ./_assets/dms-theme.txt);
    bootstrap = pkgs.writeText "dms-fzf-bootstrap" "";
  in {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = lib.mkIf (!dmsEnabled) (
        with config.lib.stylix.colors.withHashtag;
          lib.mkForce {
            bg = base00;
            "bg+" = base02;
            fg = base05;
            "fg+" = base05;
            header = base0E;
            hl = base08;
            "hl+" = base08;
            info = base0A;
            marker = base06;
            pointer = base06;
            prompt = base0E;
            spinner = base06;
          }
      );
    };
    xdg.configFile."matugen/dms/configs/fzf.toml" = lib.mkIf dmsEnabled {
      text = ''
        [templates.dmsfzf]
        input_path = '${template}'
        output_path = '${config.xdg.configHome}/fzf/dank-theme'
      '';
    };
    home.sessionVariables = lib.mkIf dmsEnabled {
      FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/dank-theme";
    };
    home.activation.dmsFzfBootstrap = lib.mkIf dmsEnabled {
      after = ["writeBoundary"];
      before = [];
      data = ''
        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/fzf/dank-theme"} ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${lib.escapeShellArg "${bootstrap}"} ${lib.escapeShellArg "${config.xdg.configHome}/fzf/dank-theme"}
        fi
      '';
    };
  };
}
