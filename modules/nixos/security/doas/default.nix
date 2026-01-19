{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.security.doas;
in {
  options.${namespace}.security.doas = {enable = mkEnableOption "Doas";};

  config = mkIf cfg.enable {
    # Disable sudo
    security.sudo.enable = false;

    # Enable and configure `doas`.
    security.doas = {
      enable = true;
      extraRules = [
        {
          # Get all enabled users who are in the wheel group
          users = lib.attrValues (lib.mapAttrs (_: user: user.name)
            (lib.filterAttrs
              (_: user: user.enable && builtins.elem "wheel" user.extraGroups)
              config.${namespace}.user));
          noPass = true;
          keepEnv = true;
        }
      ];
    };

    # Add an alias to the shell for backward-compat and convenience.
    environment.shellAliases = {sudo = "doas";};
  };
}
