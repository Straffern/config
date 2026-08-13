{den, ...}: {
  den.aspects.apps.slack.homeManager = {
    host,
    lib,
    ...
  }:
    lib.mkIf (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/Slack"];
    };
}
