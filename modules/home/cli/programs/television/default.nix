{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.television;
  ghCfg = config.${namespace}.cli.programs.gh;
  jjCfg = config.${namespace}.cli.programs.jj;
  podmanCfg = config.${namespace}.cli.programs.podman;

  channelFileNames = builtins.attrNames (builtins.readDir ./channels);
  televisionCommunityChannels = lib.genAttrs channelFileNames (
    name: builtins.readFile (./channels + "/${name}")
  );

  generalChannels = builtins.removeAttrs televisionCommunityChannels [
    "gh-prs.toml"
    "gh-issues.toml"
    "jj-bookmark.toml"
    "jj-diff.toml"
    "jj-files.toml"
    "jj-log.toml"
    "jj-op-log.toml"
    "jj-remotes.toml"
    "podman-containers.toml"
    "podman-images.toml"
    "podman-networks.toml"
    "podman-volumes.toml"
  ];

  ghChannels = lib.genAttrs [
    "gh-prs.toml"
    "gh-issues.toml"
  ] (name: televisionCommunityChannels.${name});

  jjChannels = lib.genAttrs [
    "jj-bookmark.toml"
    "jj-diff.toml"
    "jj-files.toml"
    "jj-log.toml"
    "jj-op-log.toml"
    "jj-remotes.toml"
  ] (name: televisionCommunityChannels.${name});

  podmanChannels = lib.genAttrs [
    "podman-containers.toml"
    "podman-images.toml"
    "podman-networks.toml"
    "podman-volumes.toml"
  ] (name: televisionCommunityChannels.${name});

  enabledChannels =
    generalChannels
    // lib.optionalAttrs ghCfg.enable ghChannels
    // lib.optionalAttrs jjCfg.enable jjChannels
    // lib.optionalAttrs podmanCfg.enable podmanChannels;

  channelFiles = lib.mapAttrs' (name: text: {
    name = "television/cable/${name}";
    value.text = text;
  }) enabledChannels;
in
{
  options.${namespace}.cli.programs.television = {
    enable = mkEnableOption "Television fuzzy finder";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.television ];
    xdg.configFile = channelFiles;
  };
}
