{ options, config, pkgs, lib, namespace, ... }:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.desktop.addons.swww;
in {
  options.${namespace}.desktop.addons.swww = with types; {
    enable = mkBoolOpt false "Enable or disable SWWW";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.swww
      (pkgs.writeShellScriptBin "wallpaper" ''
        /usr/bin/env ls ~/.config/wallpapers/ | sort -R | tail -1 |while read file; do
            swww img ~/.config/wallpapers/$file --transition-fps 255 --transition-type wipe
            echo "$file"
        done
      '')
    ];

    home.persist.directories = [ ".cache/swww" ];
  };
}
