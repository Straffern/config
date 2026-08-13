{
  den,
  lib,
  ...
}: let
  unfree = den.batteries.unfree [
    "steam"
    "steam-original"
    "steam-run"
    "steam-unwrapped"
  ];
in {
  den.default = {
    includes = [
      den.batteries.define-user
      den.batteries.hostname
      den.batteries.inputs'
      unfree
    ];
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";
  };

  den.schema.user.classes = lib.mkDefault ["user" "homeManager"];
}
