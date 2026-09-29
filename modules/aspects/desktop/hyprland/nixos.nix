{
  den,
  inputs,
  ...
}: {
  den.aspects.desktop.hyprland = {
    includes = [den.aspects.development.mutable-source];
    nixos = {
      config,
      pkgs,
      ...
    }: let
      unstable = inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = unstable.hyprland;
        portalPackage = unstable.xdg-desktop-portal-hyprland;
      };
      assertions = [
        {
          assertion =
            config.programs.hyprland.package.outPath
            == unstable.hyprland.outPath
            && config.programs.hyprland.portalPackage.outPath == unstable.xdg-desktop-portal-hyprland.outPath;
          message = "Hyprland must be the unmodified nixpkgs-unstable build so it substitutes from cache.nixos.org.";
        }
      ];
    };
  };
}
