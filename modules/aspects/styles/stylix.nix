{
  den,
  inputs,
  ...
}: let
  monolisaPackage = pkgs: pkgs.callPackage ./packages/_package/monolisa {};
  wallpapersPackage = pkgs: pkgs.callPackage ./packages/_package/wallpapers {};
in {
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.styles.stylix = {
    includes = [
      den.aspects.styles.monolisa
      den.aspects.styles.wallpapers
    ];
    nixos = {pkgs, ...}: let
      monolisa = monolisaPackage pkgs;
      wallpapers = wallpapersPackage pkgs;
    in {
      imports = [inputs.stylix.nixosModules.stylix];

      config.stylix = {
        enable = true;
        autoEnable = true;
        image = wallpapers.windows-error;
        polarity = "dark";
        homeManagerIntegration = {
          autoImport = false;
          followSystem = false;
        };
        cursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        fonts = {
          sizes = {
            terminal = 14;
            applications = 12;
            popups = 12;
          };
          serif = {
            name = "Source Serif";
            package = pkgs.source-serif;
          };
          sansSerif = {
            name = "Noto Sans";
            package = pkgs.noto-fonts;
          };
          monospace = {
            package = monolisa;
            name = "MonoLisa";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
    };
    homeManager = {pkgs, ...}: let
      monolisa = monolisaPackage pkgs;
      wallpapers = wallpapersPackage pkgs;
    in {
      imports = [inputs.stylix.homeModules.stylix];

      config.stylix = {
        enable = true;
        autoEnable = true;
        image = wallpapers.windows-error;
        polarity = "dark";
        opacity.terminal = 0.9;
        cursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        fonts = {
          sizes = {
            terminal = 14;
            applications = 12;
            popups = 12;
          };
          serif = {
            name = "Source Serif";
            package = pkgs.source-serif;
          };
          sansSerif = {
            name = "Noto Sans";
            package = pkgs.noto-fonts;
          };
          monospace = {
            package = monolisa;
            name = "MonoLisa";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
    };
  };
}
