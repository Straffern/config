{
  den,
  inputs,
  ...
}: {
  den.aspects.storage.impermanence-modules = {
    nixos.imports = [inputs.impermanence.nixosModules.impermanence];
  };
}
