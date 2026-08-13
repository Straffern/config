{den, ...}: {
  den.aspects.desktop.kitty.homeManager = {
    config,
    lib,
    ...
  }: let
    dmsEnabled =
      config.programs ? dank-material-shell
      && config.programs.dank-material-shell.enable;
  in
    lib.mkIf (!dmsEnabled) {
      programs.kitty.settings = {
        background_opacity = lib.mkForce 1.0;
        font_size = 14;
      };
    };
}
