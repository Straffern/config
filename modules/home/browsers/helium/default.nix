{
  lib,
  config,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.browsers.helium;
in {
  imports = [inputs.helium-browser.homeModules.default];

  options.${namespace}.browsers.helium = {
    enable = mkEnableOption "Helium";
  };

  config = mkIf cfg.enable {
    programs.helium.enable = true;

    ${namespace}.system.persistence.directories = [
      ".config/helium"
      ".cache/helium"
    ];
  };
}
