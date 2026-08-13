{
  den,
  lib,
  ...
}: {
  den.default = {
    includes = [
      den.batteries.define-user
      den.batteries.hostname
      den.batteries.inputs'
      den.batteries.self'
      (den.batteries.unfree [
        "brave"
        "davinci-resolve-studio"
        "discord"
        "goofcord"
        "slack"
        "spotify"
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ])
    ];
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";
  };

  den.schema.user.classes = lib.mkDefault ["user" "homeManager"];
}
