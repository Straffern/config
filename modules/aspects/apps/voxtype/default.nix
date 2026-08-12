{
  den,
  inputs,
  ...
}: let
  voxtype = pkgs: ((import ./_package {inherit inputs;}) pkgs pkgs).voxtype-soniox;
in {
  flake-file.inputs.voxtype = {
    url = "github:peteonrails/voxtype";
    inputs.nixpkgs.follows = "unstable";
  };

  den.aspects.apps.voxtype.homeManager = {pkgs, ...}: let
    package = voxtype pkgs;
  in {
    home.packages = [package];
    systemd.user.services.voxtype = {
      Unit = {
        Description = "VoxType push-to-talk voice-to-text daemon";
        Documentation = "https://voxtype.io";
        PartOf = ["graphical-session.target"];
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${package}/bin/voxtype daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
