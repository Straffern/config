{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.helium-browser = {
    url = "github:oxcl/nix-flake-helium-browser";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.helium.homeManager = {config, ...}: {
    imports = [inputs.helium-browser.homeModules.default];
    home.persistence."/persist".directories = [
      ".config/helium"
      ".cache/helium"
    ];
    programs.helium.enable = true;
  };
}
