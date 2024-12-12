{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.ssh;
in {
  options.${namespace}.services.ssh = {
    enable = mkEnableOption "SSH";

  };

  config = mkIf cfg.enable { };
}
