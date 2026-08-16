{den, ...}: {
  den.aspects.services.ydotool.nixos.programs.ydotool.enable = true;
  den.aspects.services.ydotool.user.extraGroups = ["ydotool"];
}
