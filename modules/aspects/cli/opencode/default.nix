{den, ...}: let
  opencode = inputs': inputs'.llm-agents.packages.opencode;
in {
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "unstable";
  };
  den.aspects.cli.opencode.homeManager = {
    inputs',
    lib,
    host,
    ...
  }:
    lib.mkMerge [
      {
        programs.opencode = {
          enable = true;
          package = opencode inputs';
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".config/opencode"];
      })
    ];
}
