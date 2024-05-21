{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.apps.tools.gnupg;

  in {
    options.apps.tools.gnupg = with types; {
      enable = mkBoolOpt false "Enable gnupg";
    };

    config = mkIf cfg.enable {
      home.programs.gpg = enabled;
    };

  }
