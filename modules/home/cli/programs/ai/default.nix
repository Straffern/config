{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.cli.programs.ai;
in {
  options.${namespace}.cli.programs.ai = {
    enable = mkEnableOption "AI tools (Claude Code and OpenCode)";

    opencode = {
      enable = mkEnableOption "OpenCode configuration";

      dotfilesPath = mkOption {
        type = types.str;
        default = "/home/${config.home.username}/.dotfiles";
        description = "Absolute path to the dotfiles repository for mutable symlinks";
      };
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

  config = mkIf cfg.enable {
    home.packages = [
      # inputs.beads.packages.${pkgs.stdenv.hostPlatform.system}.default
      # pkgs.${namespace}.bv
      pkgs.${namespace}.cass
      pkgs.ollama-vulkan
    ];

    home.file = lib.mkMerge [
      # OpenCode orchestration documentation
      (lib.mkIf cfg.opencode.enable {
        ".config/opencode/AGENTS.md" = {
          source = config.lib.asgaard.managedSource ./agents/AGENTS.md;
        };
        ".config/opencode/skill" = {
          source = ./agents/skills/.;
          recursive = true;
        };
        # ".config/opencode/opencode.json" = { source = ./agents/opencode.json; };
      })
    ];

    # AI shell command generator function
    ${namespace} = {
      cli.shells.zsh.initContent = lib.mkIf cfg.shellFunction.enable (let
        ai-shell-function = (pkgs.callPackage ../../../../../packages/ai-shell {}) {
          model = cfg.shellFunction.model;
          systemPrompt = cfg.shellFunction.systemPrompt;
        };
      in ''
        # Load ai command generator function
        source ${ai-shell-function}
      '');

      system.persistence = {
        directories = [".claude" ".config/opencode"];
        files = [".claude.json"];
      };
    };
  };
}
