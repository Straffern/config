{den, ...}: {
  den.aspects.cli.nix-search-tv.homeManager = _: {
    programs.nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
    };
  };
}
