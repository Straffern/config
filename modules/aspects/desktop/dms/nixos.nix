{
  den,
  inputs,
  ...
}: {
  den.aspects.desktop.dms = {
    includes = [
      den.aspects.services.dankgreeter
      den.aspects.styles.monolisa
    ];
    nixos = {
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.dms.nixosModules.default];
      environment = {
        sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
        systemPackages = [pkgs.kdePackages.qt6ct];
      };
      programs.dank-material-shell.enable = true;
      stylix.enable = lib.mkForce false;
      fonts.packages = with pkgs; [
        noto-fonts
        source-serif
        noto-fonts-color-emoji
      ];
    };
  };
}
