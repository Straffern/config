{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.platform.impermanence.nixos = {
    imports = [inputs.impermanence.nixosModules.impermanence];
    fileSystems."/home".neededForBoot = true;
    environment.persistence."/persist".directories = ["/var/lib/nixos"];
  };
  den.aspects.platform.impermanence.homeManager.home.persistence."/persist" = {
    directories = [];
    files = [];
  };
}
