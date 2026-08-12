{
  den,
  inputs,
  ...
}: {
  den.aspects.storage.impermanence-modules = {
    nixos.imports = [
      inputs.impermanence.nixosModules.impermanence
      inputs.persist-retro.nixosModules.persist-retro
    ];
    homeManager.imports = [
      inputs.persist-retro.nixosModules.home-manager.persist-retro
    ];
  };
}
