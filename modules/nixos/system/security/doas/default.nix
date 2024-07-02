{
  options,
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.system.security.doas;
in {
  options.system.security.doas = {
    enable = mkBoolOpt false "Whether or not to replace sudo with doas.";
  };

  config = mkIf cfg.enable {
    # Disable sudo
    security.sudo.enable = false;

    # Enable and configure `doas`.
    security.doas = {
      enable = true;
      extraRules = [
        {
          users = [config.user.name];
          noPass = false;
          keepEnv = true;
          persist = true;
        }
      ];
    };

    environment.systemPackages = [
      (pkgs.writeScriptBin "sudo" ''exec doas "$@"'')
    ];
  };
}
