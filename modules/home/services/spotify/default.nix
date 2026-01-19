{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.spotify;
in {
  options.${namespace}.services.spotify = {
    enable = mkEnableOption "Spotify service";
  };

  config = mkIf cfg.enable {
    home.packages = [
      # spotify-tui
    ];

    # services.spotifyd = {
    #   enable = true;
    # };
  };
}
