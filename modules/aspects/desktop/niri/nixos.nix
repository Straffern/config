{den, ...}: {
  den.aspects.desktop.niri.nixos = {pkgs, ...}: {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };
  };
}
