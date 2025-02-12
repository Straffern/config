{ options, config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.desktop.addons.swaync;
in {
  options.${namespace}.desktop.addons.swaync = with types; {
    enable = mkBoolOpt false "Enable or disable swaync";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ swaync libnotify ];
  };
}
