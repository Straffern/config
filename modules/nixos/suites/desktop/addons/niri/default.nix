{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.suites.desktop.addons.niri;
  inherit (lib) mkIf mkEnableOption;
in {
  options.${namespace}.suites.desktop.addons.niri = {
    enable = mkEnableOption "Niri Wayland compositor";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    programs.niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };
  };
}
