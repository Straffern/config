{den, ...}: {
  flake-file.inputs.pyprland = {
    url = "github:hyprland-community/pyprland";
    inputs.nixpkgs.follows = "hyprland/nixpkgs";
  };
  den.aspects.desktop.addons.pyprland = {
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      sessionTarget = config.wayland.systemd.target;
    in {
      xdg.configFile."pypr/config.toml".source = ./_assets/pyprland.toml;

      home.packages = with pkgs; [pyprland];

      # Pyprland daemon: survive Hyprland crash restarts
      systemd.user.services.pyprland = {
        Unit = {
          Description = "Pyprland Hyprland plugins daemon";
          After = [sessionTarget];
          PartOf = [sessionTarget];
        };
        Service = {
          ExecStart = "${pkgs.pyprland}/bin/pypr";
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [sessionTarget];
      };
    };
  };
}
