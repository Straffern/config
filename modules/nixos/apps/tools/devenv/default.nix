{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.apps.tools.devenv;
in {
  options.apps.tools.devenv = with types; {
    enable = mkBoolOpt false "Enable devenv";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      devenv
    ];

    home.persist.directories = [
      ".config/devenv"
      ".local/share/devenv"
    ];
  };
}
