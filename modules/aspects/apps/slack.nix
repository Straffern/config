{den, ...}: {
  den.aspects.apps.slack = {
    includes = [(den.batteries.unfree ["slack"])];
    homeManager = {
      lib,
      host,
      pkgs,
      ...
    }:
      {
        home.packages = [pkgs.slack];
        xdg.mimeApps.defaultApplications."x-scheme-handler/slack" = ["slack.desktop"];
      }
      // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".config/Slack"];
      };
  };
}
