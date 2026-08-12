{
  den,
  lib,
  ...
}: {
  den.default = {
    includes = [den.batteries.define-user];
    nixos.system.stateVersion = "26.05";
    nixos.nixpkgs.config.allowUnfree = true;
    homeManager.home.stateVersion = "26.05";
    homeManager.nixpkgs.config.allowUnfree = true;
  };

  den.schema.user.classes = lib.mkDefault ["homeManager"];
}
