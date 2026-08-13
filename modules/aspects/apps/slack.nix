{den, ...}: {
  den.aspects.apps.slack.homeManager = {
    lib,
    host,
    ...
  }:
    lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/Slack"];
    };
}
