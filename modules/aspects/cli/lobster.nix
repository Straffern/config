{
  den,
  inputs,
  ...
}: {
  den.aspects.cli.lobster.homeManager = {
    inputs',
    pkgs,
    ...
  }: {
    home.packages = [inputs'.lobster.packages.default pkgs.ueberzugpp];
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
  flake-file.inputs.lobster.url = "github:justchokingaround/lobster";
}
