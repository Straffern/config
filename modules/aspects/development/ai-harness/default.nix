{den, ...}: {
  den.aspects.development.ai-harness.homeManager = {config, ...}: {
    home.file.".agents/AGENTS.md".source = config.lib.mutableSources.source ./_data/AGENTS.md;
    home.file.".codex/AGENTS.md".source = config.lib.mutableSources.source ./_data/AGENTS.md;
  };
}
