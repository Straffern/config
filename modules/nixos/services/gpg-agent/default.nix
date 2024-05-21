{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.services.gpg-agent;

  in {
    options.services.gpg-agent = with types; {
      enable = mkBoolOpt false "Enable gpg-agent";
    };

    config = mkIf cfg.enable {

      home.services.gpg-agent = {
        enable = true;
        enableZshIntegration = mkIf (config.system.shell.shell == true) true;
        enableSshSupport = true;
        pinentryPackage = pkgs.pinentry-curses;
      };
    };
  }
