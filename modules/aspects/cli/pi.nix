{den, ...}: let
  pi = inputs': inputs'.llm-agents.packages.pi;
in {
  den.aspects.cli.pi.homeManager = {inputs', ...}: {
    home.packages = [(pi inputs')];
  };
}
