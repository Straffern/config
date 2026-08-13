{den, ...}: let
  opencode = inputs': inputs'.llm-agents.packages.opencode;

  managedSource = config: path:
    if config.mutableSources.active
    then config.lib.file.mkOutOfStoreSymlink (toString path)
    else path;
in {
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "unstable";
  };
  den.aspects.cli.opencode.homeManager = {
    config,
    host,
    inputs',
    lib,
    ...
  }:
    {
      programs.opencode = {
        enable = true;
        package = opencode inputs';
      };
      home.file.".config/opencode/AGENTS.md".source = managedSource config ./_data/AGENTS.md;
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/opencode"];
    };
}
