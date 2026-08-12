{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.comma = {
    url = "github:nix-community/comma";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  den.aspects.cli.nix-index.homeManager = {...}: {
    imports = [inputs.nix-index-database.homeModules.nix-index];
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    programs.nix-index-database.comma.enable = true;
  };
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
}
