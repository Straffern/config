{ options, config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.module;
in {
  options.${namespace}.module = { enable = mkEnableOption "Module"; };

  config = mkIf cfg.enable { };
}
