{den, ...}: {
  den.aspects.cli.jj.homeManager = {
    host,
    lib,
    ...
  }:
    lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/jj"];
    };
}
