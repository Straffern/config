{
  den,
  inputs,
  ...
}: let
  btop = pkgs:
    inputs.nix-wrapper-modules.wrappers.btop.wrap {
      inherit pkgs;
      settings = {
        color_theme = "Default";
        theme_background = false;
      };
    };
in {
  flake-file.inputs.nix-wrapper-modules = {
    url = "github:BirdeeHub/nix-wrapper-modules";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.cli.btop = {
    homeManager = {pkgs, ...}: {
      home.packages = [
        (btop pkgs)
      ];
    };

    packages = {pkgs, ...}: {
      btop = btop pkgs;
    };
  };
}
