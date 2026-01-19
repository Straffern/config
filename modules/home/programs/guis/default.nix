{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.programs.guis;
in {
  options.${namespace}.programs.guis = {
    enable = mkEnableOption "Gnome adwaita GUI applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      trayscale

      foliate
      pavucontrol
      pwvucontrol

      sushi
      gnome-disk-utility
      totem
      gvfs
      loupe

      nautilus
      ffmpegthumbnailer # thumbnails
      nautilus-python # enable plugins
      gst_all_1.gst-libav # thumbnails
    ];

    xdg.configFile."com.github.johnfactotum.Foliate/themes/mocha.json".text = ''
      {
          "label": "Mocha",
          "light": {
          	"fg": "#999999",
          	"bg": "#cccccc",
          	"link": "#666666"
          },
          "dark": {
          	"fg": "#cdd6f4",
          	"bg": "#1e1e2e",
          	"link": "#E0DCF5"
          }
      }
    '';
  };
}
