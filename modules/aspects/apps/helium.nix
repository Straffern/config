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
    host,
    lib,
    ...
  }:
    {
      imports = [inputs.helium-browser.homeModules.default];
      programs.helium.enable = true;
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [
        ".config/helium"
        ".cache/helium"
      ];
    };
}
