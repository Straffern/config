{ inputs, pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.lobster;
in {
  options.${namespace}.cli.programs.lobster = {
    enable = mkEnableOption "lobster";
  };

  config = mkIf cfg.enable {
    home.packages =
      [ inputs.lobster.packages.${pkgs.system}.default pkgs.ueberzugpp ];

    # use_ueberzugpp=true
    xdg.configFile."lobster/lobster_config.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        preview_window_size=50%
        ueberzug_x=$(($(tput cols) - 70))
        ueberzug_y=$(($(tput lines) / 10))
        ueberzug_max_width=100
        ueberzug_max_height=100
        ueberzug_output=sixel

        history=1

        image_preview=1
        download_dir=~/Videos
      '';
    };
  };
}
