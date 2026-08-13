{den, ...}: {
  den.aspects.apps.slack.homeManager = _: {
    home.persistence."/persist".directories = [".config/Slack"];
  };
}
