{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.hyprland.url = "github:hyprwm/hyprland";
  den.aspects.desktop.hyprland = {
    includes = [den.aspects.desktop.tuigreet];
    nixos = {
      imports = [inputs.hyprland.nixosModules.default];
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
      };
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
    };
  };
}
