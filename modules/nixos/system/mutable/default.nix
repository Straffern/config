{
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.${namespace}.mutable;
in {
  options.${namespace}.mutable = {
    enable = mkEnableOption ''
      mutable specialisation generation.
      When enabled, builds an alternative "mutable" specialisation
      selectable at boot where managed files symlink to the dotfiles repo.
    '';

    active = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = "Whether mutable mode is currently active";
    };
  };

  config = mkIf cfg.enable {
    specialisation.mutable.configuration = {
      ${namespace}.mutable.active = true;
    };
  };
}
