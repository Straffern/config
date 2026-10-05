{den, ...}: {
  den.aspects.cli.omp.homeManager = {inputs', ...}: {
    home.packages = [inputs'.llm-agents.packages.omp];
  };
}
