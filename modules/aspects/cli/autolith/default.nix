{den, ...}: {
  # Config only: the autolith binary is installed imperatively with
  # `nix profile`, because it releases faster than this flake's lock moves.
  den.aspects.cli.autolith = {
    includes = [den.aspects.development.mutable-source];

    homeManager = {config, ...}: {
      xdg.configFile."autolith/init.lisp".source = config.lib.mutableSources.source ./_config/init.lisp;
      xdg.configFile."autolith/pstack-models.md".source = config.lib.mutableSources.source ./_config/pstack-models.md;
    };
  };
}
