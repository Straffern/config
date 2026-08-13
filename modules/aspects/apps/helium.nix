{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.helium-browser = {
    url = "github:oxcl/nix-flake-helium-browser";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.helium.homeManager = {
    lib,
    host,
    ...
  }: {
    imports = [inputs.helium-browser.homeModules.default];
    config = lib.mkMerge [
      {programs.helium.enable = true;}
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [
          ".config/helium"
          ".cache/helium"
        ];
      })
    ];
  };
}
