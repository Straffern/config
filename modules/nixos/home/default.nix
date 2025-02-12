{ options, config, lib, namespace, ... }:
with lib;
with lib.${namespace};
let
  inherit (lib) mkIf mkEnableOption types;
  # inherit (lib.${namespace}) types;
  cfg = config.${namespace}.home;
in {
  options.${namespace}.home = with types; {
    file = mkOpt attrs { }
      (mdDoc "A set of files to be managed by home-manager's `home.file`.");
    configFile = mkOpt attrs { } (mdDoc
      "A set of files to be managed by home-manager's `xdg.configFile`.");
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    ${namespace}.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions cfg.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions cfg.configFile;
    };

    snowfallorg.users.${config.${namespace}.user.name}.home.config =
      cfg.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
