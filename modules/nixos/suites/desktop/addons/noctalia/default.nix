{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.suites.desktop.addons.noctalia;
  inherit (lib) mkForce mkIf mkEnableOption;
in {
  options.${namespace}.suites.desktop.addons.noctalia = {
    enable = mkEnableOption "Noctalia desktop shell system integration";
  };

  config = mkIf cfg.enable {
    # Noctalia needs power-profiles-daemon for its power profile widget.
    services.power-profiles-daemon.enable = true;

    # Noctalia owns all theming; Stylix conflicts.
    ${namespace}.styles.stylix.enable = mkForce false;

    # qt6ct provides dedicated Qt theming control.
    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    # qt6ct-kde variant needed for KColorScheme support (Dolphin, etc.).
    environment.systemPackages = [pkgs.kdePackages.qt6ct];
  };
}
