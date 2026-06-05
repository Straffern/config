{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.television;
  ghCfg = config.${namespace}.cli.programs.gh;
  jjCfg = config.${namespace}.cli.programs.jj;
  podmanCfg = config.${namespace}.cli.programs.podman;

  communityChannel = name:
    builtins.fromTOML (
      builtins.readFile "${pkgs.television.src}/cable/unix/${name}.toml"
    );

  generalChannels = [
    "journal"
    "ports"
    "ssh-hosts"
    "tailscale-exit-node"
  ];

  ghChannels = [
    "gh-prs"
    "gh-issues"
  ];

  jjChannels = [
    "jj-bookmark"
    "jj-diff"
    "jj-files"
    "jj-log"
    "jj-op-log"
    "jj-remotes"
  ];

  podmanChannels = [
    "podman-containers"
    "podman-images"
    "podman-networks"
    "podman-volumes"
  ];

  enabledChannelNames =
    generalChannels
    ++ lib.optionals ghCfg.enable ghChannels
    ++ lib.optionals jjCfg.enable jjChannels
    ++ lib.optionals podmanCfg.enable podmanChannels;

  channels = lib.genAttrs enabledChannelNames communityChannel;
in {
  options.${namespace}.cli.programs.television = {
    enable = mkEnableOption "Television fuzzy finder";
  };

  config = mkIf cfg.enable {
    programs.television = {
      enable = true;
      package = pkgs.television;
      inherit channels;
    };
  };
}
