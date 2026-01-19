{
  pkgs,
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.podman;
in {
  options.${namespace}.cli.programs.podman = {
    enable = mkEnableOption "Manage Podman";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      arion
      podman
      podman-compose
      podman-tui
      amazon-ecr-credential-helper

      lazydocker
    ];
  };
}
