# Closed-beta build. Once Tern ships publicly (watch numtide/llm-agents.nix),
# delete this directory, or swap the
# package for `inputs'.llm-agents.packages.tern`.
{den, ...}: {
  den.aspects.cli.tern = {
    includes = [(den.batteries.unfree ["tern"])];
    homeManager = {pkgs, ...}: {
      home.packages = [(pkgs.callPackage ./_package {})];
    };
  };
}
