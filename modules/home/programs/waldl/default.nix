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

  # Handle API Key from sops if sops is enabled
  sopsEnabled = config.${namespace}.security.sops.enable;

  apiKeyScript =
    if sopsEnabled
    then "export WALDL_API_KEY=$(cat ${config.sops.secrets.wallhaven_key.path})"
    else if cfg.apiKeyFile != null
    then "export WALDL_API_KEY=$(cat ${cfg.apiKeyFile})"
    else if cfg.apiKey != ""
    then ''export WALDL_API_KEY="${cfg.apiKey}"''
    else "";

  # Only write WALDL_* vars when explicitly set (non-null)
  # This allows the settings file to persist user choices at runtime
  configContent = lib.concatStringsSep "\n" (lib.filter (s: s != "") [
    (lib.optionalString (cfg.sorting != null)
      ''WALDL_SORTING="${cfg.sorting}"'')
    (lib.optionalString (cfg.purity != null) ''WALDL_PURITY="${cfg.purity}"'')
    (lib.optionalString (cfg.categories != null)
      ''WALDL_CATEGORIES="${cfg.categories}"'')
    (lib.optionalString (cfg.atleast != null)
      ''WALDL_ATLEAST="${cfg.atleast}"'')
    ''WALDL_MAX_PAGES="${toString cfg.maxPages}"''
    ''WALDL_WALLDIR="${cfg.walldir}"''
    ''MENU="${cfg.menu}"''
    ''VIEWER="${cfg.viewer}"''
    (lib.optionalString (cfg.postDownloadCmd != "")
      ''WALDL_POST_DOWNLOAD_CMD="${cfg.postDownloadCmd}"'')
  ]);
in {
  options.${namespace}.programs.waldl = {
    enable = mkEnableOption "Enable waldl Wallhaven downloader";

    sorting =
      mkOpt (types.nullOr types.str) null
      "Override sorting order (null = use runtime settings)";
    purity =
      mkOpt (types.nullOr types.str) null
      "Override purity bitfield (null = use runtime settings)";
    categories =
      mkOpt (types.nullOr types.str) null
      "Override categories bitfield (null = use runtime settings)";
    atleast =
      mkOpt (types.nullOr types.str) null
      "Override minimum resolution (null = use runtime settings)";
    maxPages = mkOpt types.int 2 "Number of pages to fetch";
    walldir =
      mkOpt types.str
      "${config.home.homeDirectory}/.local/share/wallpapers/wallhaven"
      "Directory to save wallpapers";
    menu =
      mkOpt (types.enum ["rofi" "tofi" "dmenu"]) "rofi" "Menu tool to use";
    viewer = mkOpt (types.enum ["nsxiv" "imv"]) "nsxiv" "Image viewer to use";

    apiKey = mkOpt types.str "" "Wallhaven API Key (stored in Nix store!)";
    apiKeyFile =
      mkOpt (types.nullOr types.path) null
      "Path to file containing API Key (recommended)";

    postDownloadCmd =
      mkOpt types.str ""
      "Command to run after downloading (e.g. to set wallpaper)";

    applyWallpaper =
      mkOpt types.bool false
      "Automatically set postDownloadCmd for Hyprland if enabled";
  };

  config = mkIf cfg.enable {
    home.packages = [waldl-pkg];

    sops.secrets.wallhaven_key =
      mkIf sopsEnabled {sopsFile = ../../../../secrets.yaml;};

    xdg.configFile."waldl/config".text = configContent + "\n" + apiKeyScript;

    # Integration with Hyprland/Hyprpaper
    ${namespace}.programs.waldl.postDownloadCmd =
      mkIf (cfg.applyWallpaper && config.${namespace}.desktops.hyprland.enable)
      (lib.mkDefault ''
        # Basic hyprpaper application logic
        # This assumes hyprpaper is running and configured
        latest_img=\$(ls -t "${cfg.walldir}" | head -n 1)
        if [[ -n "\$latest_img" ]]; then
          full_path="${cfg.walldir}/\$latest_img"
          hyprctl hyprpaper preload "\$full_path"
          # Apply to all monitors for simplicity
          for mon in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
            hyprctl hyprpaper wallpaper "\$mon,\$full_path"
          done
        fi
      '');
  };
}
