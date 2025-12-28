{ lib, config, namespace, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.${namespace}.mutable;
in {
  options.${namespace}.mutable = {
    enable = mkEnableOption ''
      mutable specialisation generation.
      When enabled, builds an alternative "mutable" specialisation
      where managed files symlink to the dotfiles repo instead of the Nix store.
      Disable for systems that should always be immutable.
    '';

    # Internal: set by specialisation, not by users
    active = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = "Whether mutable mode is currently active";
    };
  };

  config = {
    lib.asgaard.managedSource = path:
      if cfg.active
      then config.lib.file.mkOutOfStoreSymlink (toString path)
      else path;

    specialisation = mkIf cfg.enable {
      mutable.configuration = {
        ${namespace}.mutable.active = true;
      };
    };
  };
}
