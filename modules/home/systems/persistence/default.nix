{ lib, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.system.persistence;

  # Check if NixOS impermanence is enabled
  impermanenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;

  # Directory entry type - supports both strings and { directory, method } attrsets
  directoryType = types.either types.str (types.submodule {
    options = {
      directory = mkOption {
        type = types.str;
        description = "The directory path to be linked.";
      };
      method = mkOption {
        type = types.enum [ "bindfs" "symlink" ];
        default = cfg.defaultDirectoryMethod;
        description = "The linking method for this directory.";
      };
    };
  });
in {
  options.${namespace}.system.persistence = {
    enable = mkBoolOpt impermanenceEnabled
      "Whether to enable home persistence. Automatically enabled when NixOS impermanence is active.";

    persistPrefix = mkOption {
      type = types.str;
      default = "/persist/home/${config.home.username}";
      description = "The persistence directory prefix for home files.";
    };

    allowOther = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow other users (like root) access to bind mounted directories.";
    };

    defaultDirectoryMethod = mkOption {
      type = types.enum [ "bindfs" "symlink" ];
      default = "bindfs";
      description = ''
        Default linking method for directories.
        - bindfs: transparent but slower IO
        - symlink: fast but some programs handle symlinks specially
      '';
    };

    directories = mkOption {
      type = types.listOf directoryType;
      default = [ ];
      description = "Directories to persist.";
      example = [
        ".config/my-app"
        ".local/share/my-app"
        { directory = ".local/share/Steam"; method = "symlink"; }
      ];
    };

    files = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Files to persist.";
      example = [ ".screenrc" ".my-config-file" ];
    };
  };

  config = mkIf cfg.enable {
    programs.persist-retro.enable = true;

    home.persistence.${cfg.persistPrefix} = {
      inherit (cfg) allowOther directories files;
      defaultDirectoryMethod = cfg.defaultDirectoryMethod;
    };
  };
}
