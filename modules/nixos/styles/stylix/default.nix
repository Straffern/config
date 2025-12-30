{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.${namespace}.styles.stylix;
in {
  options.${namespace}.styles.stylix = {
    enable = mkEnableOption "Stylix";

    wallpaper = mkOption {
      type = with types; either package path;
      default = pkgs.${namespace}.wallpapers.windows-error;
      description = "The wallpaper to use for the system theme";
    };

    enableBase16 = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable base16 color scheme";
    };

    base16Scheme = mkOption {
      type = types.path;
      default = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      description = "The base16 color scheme to use when enableBase16 is true";
    };

    polarity = mkOption {
      type = types.enum [ "light" "dark" ];
      default = "dark";
      description = "Whether to use a light or dark color scheme";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig = {
        enable = true;

        localConf = ''
          <alias>
            <family>monospace</family>
            <prefer><family>Symbols Nerd Font</family></prefer>
          </alias>
        '';
      };
    };

    stylix = {
      enable = true;
      autoEnable = true;

      base16Scheme = lib.mkIf cfg.enableBase16 cfg.base16Scheme;
      homeManagerIntegration.autoImport = false;
      homeManagerIntegration.followSystem = false;

      image = cfg.wallpaper;
      polarity = cfg.polarity;

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
