{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.social;
in {
  options.${namespace}.suites.social = {
    enable = mkEnableOption "Enable social suite";
  };

  config = mkIf cfg.enable {
    ${namespace}.programs = {
      discord = enabled;
      shotwell = enabled;
    };
  };
}
