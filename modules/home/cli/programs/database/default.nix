{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace}; let
  cfg = config.${namespace}.cli.programs.db;
in {
  options.${namespace}.cli.programs.db = with types; {
    enable = mkBoolOpt false "Whether or not to manage db";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # dbeaver-bin
      termdbms
    ];
  };
}
