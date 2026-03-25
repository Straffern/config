{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.suites.desktop.addons.dms;
  inherit (lib) mkForce mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
in {
  options.${namespace}.suites.desktop.addons.dms = {
    enable = mkEnableOption "DankMaterialShell system integration";
  };

  config = mkIf cfg.enable {
    # qt6ct provides dedicated Qt theming control; DMS generates color schemes for it.
    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    # qt6ct-kde variant needed for KColorScheme support (Dolphin, etc.).
    environment.systemPackages = [pkgs.kdePackages.qt6ct];

    # DMS NixOS module handles polkit, power-profiles-daemon, accounts-daemon,
    # geoclue2, system packages (quickshell, dgop, matugen, etc.), and plugins.
    programs.dank-material-shell.enable = true;

    # DMS owns all theming; Stylix's NixOS targets conflict.
    ${namespace} = {
      styles.stylix.enable = mkForce false;
      services.dankgreeter = enabled;
    };

    # DMS/greeter need fonts at system level (not just HM profile).
    fonts.packages = [
      pkgs.${namespace}.monolisa
      pkgs.noto-fonts
      pkgs.source-serif
      pkgs.noto-fonts-color-emoji
    ];
  };
}
