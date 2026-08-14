{
  den,
  inputs,
  ...
}: let
  monolisaPackage = pkgs: pkgs.callPackage ./packages/_package/monolisa {};
  wallpapersPackage = pkgs: pkgs.callPackage ./packages/_package/wallpapers {};
in {
  den.aspects.styles.stylix.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;
    monolisa = monolisaPackage pkgs;
    wallpapers = wallpapersPackage pkgs;
    cfg = config.styles.stylix;
  in {
    imports = [inputs.stylix.homeModules.stylix];
    options.styles.stylix = {
      useCatppuccinNative = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use native catppuccin modules instead of Stylix auto-theming for supported apps";
      };
      wallpaper = mkOption {
        type = types.either types.package types.path;
        default = wallpapers.windows-error;
        description = "The wallpaper to use for the system theme";
      };
      base16Scheme = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "The base16 color scheme to use. If null, a scheme will be generated from the wallpaper.";
      };
      polarity = mkOption {
        type = types.enum [
          "light"
          "dark"
        ];
        default = "dark";
        description = "Whether to use a light or dark color scheme";
      };
      patch = {
        brightness = mkOption {
          type = types.int;
          default = 0;
          description = "The brightness to apply to the wallpaper (-100 to 100)";
        };
        contrast = mkOption {
          type = types.int;
          default = 0;
          description = "The contrast to apply to the wallpaper (-100 to 100)";
        };
        recolor = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to recolor the wallpaper to match the theme palette";
        };
      };
    };

    config = {
      assertions = [
        {
          assertion = cfg.patch.brightness >= -100 && cfg.patch.brightness <= 100;
          message = "styles.stylix.patch.brightness must be between -100 and 100";
        }
        {
          assertion = cfg.patch.contrast >= -100 && cfg.patch.contrast <= 100;
          message = "styles.stylix.patch.contrast must be between -100 and 100";
        }
        {
          assertion = cfg.patch.recolor -> cfg.base16Scheme != null;
          message = "styles.stylix.patch.recolor requires a manual styles.stylix.base16Scheme to avoid infinite recursion";
        }
      ];

      stylix = {
        enable = true;
        autoEnable = !cfg.useCatppuccinNative;
        base16Scheme = lib.mkIf (cfg.base16Scheme != null) cfg.base16Scheme;
        icons = {
          enable = true;
          package = pkgs.catppuccin-papirus-folders.override {
            flavor = "mocha";
            accent = "lavender";
          };
          dark = "Papirus-Dark";
        };

        image = let
          canRecolor = cfg.patch.recolor && cfg.base16Scheme != null;
          isModified = cfg.patch.brightness != 0 || cfg.patch.contrast != 0 || canRecolor;
          colors =
            if canRecolor
            then config.lib.stylix.colors
            else {};
          palette = lib.concatStringsSep " " (
            map (k: "#${colors.${k}}") (lib.sort lib.lessThan (lib.attrNames colors))
          );
        in
          if isModified
          then
            pkgs.runCommand "modified-wallpaper.png"
            {
              nativeBuildInputs = with pkgs; [
                imagemagick
                lutgen
              ];
            }
            ''
              set -euo pipefail
              cp "${cfg.wallpaper}" ./temp_image
              chmod +w ./temp_image
              ${lib.optionalString (canRecolor && colors != {}) ''
                ${lib.getExe pkgs.lutgen} apply ./temp_image -p ${palette} -o ./temp_image
              ''}
              ${lib.optionalString (cfg.patch.brightness != 0 || cfg.patch.contrast != 0) ''
                ${lib.getExe' pkgs.imagemagick "magick"} ./temp_image -brightness-contrast ${toString cfg.patch.brightness},${toString cfg.patch.contrast} ./temp_image
              ''}
              cp ./temp_image $out
            ''
          else cfg.wallpaper;
        inherit (cfg) polarity;
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
