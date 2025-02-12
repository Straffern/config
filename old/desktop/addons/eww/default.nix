{ options, config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.desktop.addons.eww;
in {
  options.${namespace}.desktop.addons.eww = with types; {
    enable = mkBoolOpt false "Enable or disable EWW.";
    wayland = mkBoolOpt false "Enable wayland support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      eww-wayland

      playerctl
      gojq
      jaq
      socat
    ];

    home.configFile."eww/" = {
      recursive = true;
      source = ./config;
    };
  };
}
