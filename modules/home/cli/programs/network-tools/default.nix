{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.network-tools;
in {
  options.${namespace}.cli.programs.network-tools = {
    enable = mkEnableOption "Network tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ tshark termshark kubeshark ];
  };
}
