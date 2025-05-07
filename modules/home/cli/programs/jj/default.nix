{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.jj;
  colors = config.lib.stylix.colors; # Access Stylix colors

in {
  options.${namespace}.cli.programs.jj = with types; {
    enable = mkEnableOption "jujutsu";
    userName = mkOpt (nullOr str) "Alexander Flensborg"
      "The name appearing on the commits";
    email =
      mkOpt (nullOr str) "alex@flensborg.dev" "The email to use with git.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ lazyjj jujutsu watchman ];

    programs.jujutsu = {
      enable = true;
      settings = {

        core.fsmonitor = "watchman";
        core.watchman.register-snapshot-trigger = true;

        user = {
          email = cfg.email;
          name = cfg.userName;
        };

        ui = {
          default-command = "status";
          pager = "delta";
          # diff.format = "git";
          show-cryptographic-signatures = true;
        };

        colors = {
          commit_id = {
            # fg = "#${colors.base0A}";
            fg = "#0000ff";
            # bg = "#00008f";
            bold = true;
          }; # e.g., #00008f for blue
          change_id = {
            # fg = "#${colors.base0E}";
            fg = "#7f00ff";
            # bg = "#7f00ff";
            italic = true;
          }; # e.g., #7f00ff for magenta
          "working_copy commit_id" = { underline = true; };
          "diff removed token" = {
            fg = "#${colors.base08}";
            # fg = "#${colors.base05}";
            bg = "#ff0000";
            underline = false;
          }; # e.g., #ff0000 for red
          "diff added token" = {
            fg = "#${colors.base0B}";
            # fg = "#${colors.base05}";
            bg = "#007f00";
            underline = false;
          }; # e.g., #00ff00 for green
        };

        signing = let gitCfg = config.programs.git.extraConfig;
        in {
          backend = "ssh";
          behaviour = if gitCfg.commit.gpgsign then "own" else "never";
          key = gitCfg.user.signingkey;
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.email().local()";
        };

        git.sign-on-push = true;

      };
    };

    ${namespace}.cli.shells.zsh.initExtra = ''
      autoload -U compinit
      compinit
      source <(jj util completion zsh)
    '';
  };
}
