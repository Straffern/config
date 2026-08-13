{den, ...}: let
  pi = inputs': inputs'.llm-agents.packages.pi;
  herdr = inputs': inputs'.llm-agents.packages.herdr;
in {
  den.aspects.cli.pi.homeManager = {inputs', ...}: {
    home.packages = [
      (pi inputs')
      (herdr inputs')
    ];
  };
}
