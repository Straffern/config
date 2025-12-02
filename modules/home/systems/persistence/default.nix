{ lib, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.persistence;

  # Check if NixOS impermanence is enabled
  impermanenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.system.persistence = {
    enable = mkBoolOpt impermanenceEnabled
      "Whether to enable home persistence. Automatically enabled when NixOS impermanence is active.";

    persistPrefix = mkOption {
      type = types.str;
      default = "/persist/home/${config.home.username}";
      description = "The persistence directory prefix for home files.";
    };

    extraDirectories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional directories to persist.";
      example = [ ".config/my-app" ".local/share/my-app" ];
    };

    extraFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional files to persist.";
      example = [ ".my-config-file" ];
    };
  };

  config = mkIf cfg.enable {
    # Apply extra directories/files if specified
    home.persistence.${cfg.persistPrefix} = mkIf
      (cfg.extraDirectories != [ ] || cfg.extraFiles != [ ]) {
        allowOther = true;
        directories = cfg.extraDirectories;
        files = cfg.extraFiles;
      };
  };
}
