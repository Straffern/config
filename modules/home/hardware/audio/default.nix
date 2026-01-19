{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.hardware.audio;

  # Helper to generate WirePlumber rules
  mkRule = {
    name,
    priority,
  }: {
    matches = [{"node.name" = name;}];
    actions = {"update-props" = {"priority.session" = priority;};};
  };
in {
  options.${namespace}.hardware.audio = {
    enable = mkEnableOption "User-specific audio configuration";

    priorities = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "The node.name pattern to match (regex supported)";
          };
          priority = mkOption {
            type = types.int;
            description = "The session priority (higher wins)";
          };
        };
      });
      default = [];
      description = "Custom microphone priority rules";
    };
  };

  config = mkIf cfg.enable {
    # Microphone Hierarchy Drop-in
    xdg.configFile."wireplumber/wireplumber.conf.d/11-microphone-hierarchy.conf".text =
      builtins.toJSON {"monitor.alsa.rules" = map mkRule cfg.priorities;};
  };
}
