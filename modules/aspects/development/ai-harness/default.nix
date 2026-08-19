{den, ...}: let
  managedSource = config: path:
    if config.mutableSources.active
    then config.lib.file.mkOutOfStoreSymlink (toString path)
    else path;
in {
  den.aspects.development.ai-harness.homeManager = {config, ...}: {
    home.file.".agents/AGENTS.md".source = managedSource config ./_data/AGENTS.md;
  };
}
