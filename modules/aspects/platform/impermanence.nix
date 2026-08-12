{den, ...}: {
  flake-file.inputs = {
    persist-retro.url = "github:straffern/persist-retro";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  den.aspects.platform.impermanence.includes = [
    den.aspects.storage.impermanence-modules
  ];

  den.aspects.platform.impermanence.nixos.fileSystems."/home".neededForBoot = true;
  den.aspects.platform.impermanence.homeManager = {config, ...}: {
    programs.persist-retro.enable = true;
    home.persistence."/persist" = {
      allowOther = true;
      defaultDirectoryMethod = "bindfs";
      directories = [];
      files = [];
    };
  };
}
