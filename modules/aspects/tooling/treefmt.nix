{
  den,
  inputs,
  self,
  ...
}: {
  den.aspects.tooling.treefmt = {
    flake-parts = {pkgs, ...}: let
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
        programs.deadnix = {
          enable = true;
          no-lambda-pattern-names = true;
          no-underscore = true;
        };
        programs.statix.enable = true;
      };
    in {
      formatter = treefmtEval.config.build.wrapper;
      checks.treefmt = treefmtEval.config.build.check self;
    };
  };

  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
