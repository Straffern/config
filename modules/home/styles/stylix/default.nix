{ lib, pkgs, config, namespace, ... }:
let

  inherit (lib) mkOption mkEnableOption types;
  cfg = config.${namespace}.styles.stylix;
in {

  options.${namespace}.styles.stylix = {
    enable = mkEnableOption
      "Stylix (palette can be viewed at ~/.config/stylix/palette.html)";

    useCatppuccinNative = mkOption {
      type = types.bool;
      default = false;
      description =
        "Whether to use native catppuccin modules instead of Stylix auto-theming for supported apps";
    };

    wallpaper = mkOption {
      type = with types; either package path;
      default = pkgs.${namespace}.wallpapers.windows-error;
      description = "The wallpaper to use for the system theme";
    };

    base16Scheme = mkOption {
      type = types.nullOr types.path;
      default = null;
      description =
        "The base16 color scheme to use. If null, a scheme will be generated from the wallpaper.";
    };

    polarity = mkOption {
      type = types.enum [ "light" "dark" ];
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

      recolor =
        mkEnableOption "recoloring the wallpaper to match the theme palette";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.patch.brightness >= -100 && cfg.patch.brightness <= 100;
        message = "stylix.patch.brightness must be between -100 and 100";
      }
      {
        assertion = cfg.patch.contrast >= -100 && cfg.patch.contrast <= 100;
        message = "stylix.patch.contrast must be between -100 and 100";
      }
      {
        assertion = cfg.patch.recolor -> cfg.base16Scheme != null;
        message =
          "stylix.patch.recolor requires a manual stylix.base16Scheme to avoid infinite recursion";
      }
    ];

    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [ nerd-fonts.symbols-only open-sans ];

    # Catppuccin integration
    catppuccin.enable = cfg.useCatppuccinNative;
    catppuccin.flavor = "mocha";
    catppuccin.zsh-syntax-highlighting.enable = cfg.useCatppuccinNative;

    stylix = {
      enable = true;
      autoEnable = !cfg.useCatppuccinNative;
      base16Scheme = lib.mkIf (cfg.base16Scheme != null) cfg.base16Scheme;

      iconTheme = {
        enable = true;
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "lavender";
        };
        dark = "Papirus-Dark";
      };

      targets = {
        librewolf = {
          firefoxGnomeTheme.enable = true;
          profileNames = [ "Default" ];
        };
      };

      image = let
        # Only allow recoloring if an explicit scheme is provided.
        # This prevents infinite recursion when Stylix tries to generate
        # a scheme from the image we are currently processing.
        canRecolor = cfg.patch.recolor && cfg.base16Scheme != null;

        isModified = cfg.patch.brightness != 0 || cfg.patch.contrast != 0
          || canRecolor;

        colors = if canRecolor then config.lib.stylix.colors else { };
        palette = lib.concatStringsSep " " (map (k: "#${colors.${k}}")
          (lib.sort lib.lessThan (lib.attrNames colors)));

      in if isModified then
        pkgs.runCommand "modified-wallpaper.png" {
          nativeBuildInputs = with pkgs; [ imagemagick lutgen ];
        } ''
          set -euo pipefail
          cp "${cfg.wallpaper}" ./temp_image
          chmod +w ./temp_image

          ${lib.optionalString (canRecolor && colors != { }) ''
            ${
              lib.getExe pkgs.lutgen
            } apply ./temp_image -p ${palette} -o ./temp_image
          ''}

          ${lib.optionalString
          (cfg.patch.brightness != 0 || cfg.patch.contrast != 0) ''
            ${
              lib.getExe' pkgs.imagemagick "magick"
            } ./temp_image -brightness-contrast ${
              toString cfg.patch.brightness
            },${toString cfg.patch.contrast} ./temp_image
          ''}

          cp ./temp_image $out
        ''
      else
        cfg.wallpaper;

      polarity = cfg.polarity;

      opacity = { terminal = 0.9; };

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
          package = pkgs.${namespace}.monolisa;
          name = "MonoLisa";
        };

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };
    };
  };
}
