{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.programs.waldl;

  waldl-pkg = pkgs.${namespace}.waldl;

  sopsEnabled = config.${namespace}.security.sops.enable;

  # Build the TOML config matching waldl's Config struct.
  tomlConfig = let
    # [general]
    general =
      {
        wallpaper_dir = cfg.walldir;
      }
      // lib.optionalAttrs (cfg.wallpaperCommand != null) {
        wallpaper_command = cfg.wallpaperCommand;
      }
      // lib.optionalAttrs (cfg.previewCommand != null) {
        preview_command = cfg.previewCommand;
      };

    # [api] — key_file is the preferred path; key is a fallback
    api =
      lib.optionalAttrs (cfg.apiKey != "") {key = cfg.apiKey;}
      // lib.optionalAttrs (cfg.apiKeyFile != null) {
        key_file = toString cfg.apiKeyFile;
      }
      // lib.optionalAttrs sopsEnabled {
        key_file = config.sops.secrets.wallhaven_key.path;
      };

    # [defaults] — only emit non-null overrides
    defaults =
      lib.optionalAttrs (cfg.sorting != null) {inherit (cfg) sorting;}
      // lib.optionalAttrs (cfg.purity != null) {inherit (cfg) purity;}
      // lib.optionalAttrs (cfg.categories != null) {inherit (cfg) categories;}
      // lib.optionalAttrs (cfg.atleast != null) {inherit (cfg) atleast;}
      // lib.optionalAttrs (cfg.toplistRange != null) {toplist_range = cfg.toplistRange;};
  in {
    inherit general api;
    inherit defaults;
  };
in {
  options.${namespace}.programs.waldl = {
    enable = mkEnableOption "Enable waldl Wallhaven wallpaper browser TUI";

    walldir =
      mkOpt types.str "${config.home.homeDirectory}/Pictures/wallpapers/wallhaven"
      "Directory to save wallpapers";

    wallpaperCommand =
      mkOpt (types.nullOr types.str) null
      "Command to set wallpaper. {path} is replaced with the file path.";

    previewCommand =
      mkOpt (types.nullOr types.str) null
      "Command to preview an image externally. {path} is replaced.";

    sorting =
      mkOpt (types.nullOr types.str) null
      "Default sorting (date_added, relevance, random, favorites, toplist, views)";
    purity =
      mkOpt (types.nullOr types.str) null
      "Purity bitfield (100=SFW, 010=Sketchy, 001=NSFW, combinations)";
    categories =
      mkOpt (types.nullOr types.str) null
      "Category bitfield (100=General, 010=Anime, 001=People, combinations)";
    atleast =
      mkOpt (types.nullOr types.str) null
      "Minimum resolution (e.g. 1920x1080, or auto to detect)";
    toplistRange =
      mkOpt (types.nullOr types.str) null
      "Toplist time range (1d, 3d, 1w, 1M, 3M, 6M, 1y)";

    apiKey = mkOpt types.str "" "Wallhaven API key (stored in Nix store — use apiKeyFile instead)";
    apiKeyFile =
      mkOpt (types.nullOr types.str) null
      "Path to file containing API key (e.g. sops-nix secret)";
  };

  config = mkIf cfg.enable {
    home.packages = [waldl-pkg];

    sops.secrets.wallhaven_key = mkIf sopsEnabled {sopsFile = ../../../../secrets.yaml;};

    xdg.configFile."waldl/config.toml".source =
      (pkgs.formats.toml {}).generate "waldl-config.toml"
      tomlConfig;
  };
}
