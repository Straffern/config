{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.${namespace}.cli.programs.ai;
in {
  options = {
    programs.opencode.tui.theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Compatibility option for Stylix until Home Manager exposes OpenCode tui.json settings.";
    };

    ${namespace}.cli.programs.ai = {
      enable = mkEnableOption "AI tools";

      opencode = {
        enable = mkEnableOption "OpenCode configuration";
      };

      shellFunction = {
        enable = mkEnableOption "AI command generator zsh function";

        model = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "anthropic/claude-opus-4-1-20250805";
          description = ''
            Model to use for command generation.
            If null, uses OpenCode's configured default model.
          '';
        };

        systemPrompt = mkOption {
          type = types.str;
          default = "Generate ONLY the exact shell command needed. No explanations, no markdown, no formatting - just the raw command. DO NOT USE ANY TOOLS.";
          description = "System prompt for command generation";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = lib.mkIf cfg.opencode.enable {
      enable = true;
      package = pkgs.opencode;
    };

    home.file = lib.mkMerge [
      (lib.mkIf cfg.opencode.enable {
        ".config/opencode/AGENTS.md" = {
          source = config.lib.asgaard.managedSource ./AGENTS.md;
        };
      })
    ];

    # AI shell command generator function
    ${namespace} = {
      cli.shells.zsh.initContent = lib.mkIf cfg.shellFunction.enable (
        let
          ai-shell-function = (pkgs.callPackage ../../../../../packages/ai-shell {}) {
            inherit (cfg.shellFunction) model systemPrompt;
          };
        in ''
          # Load ai command generator function
          source ${ai-shell-function}
        ''
      );

      system.persistence = {
        directories = [
          ".config/opencode"
        ];
      };
    };
  };
}
