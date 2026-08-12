{den, ...}: {
  den.aspects.desktop.noctalia.nixos = {
    lib,
    pkgs,
    ...
  }: {
    services.power-profiles-daemon.enable = true;
    stylix.enable = lib.mkForce false;
    environment = {
      sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
      systemPackages = [pkgs.kdePackages.qt6ct];
    };
  };
}
