{den, ...}: {
  den.aspects.apps.discord.homeManager = {
    lib,
    host,
    pkgs,
    ...
  }:
    lib.mkMerge [
      {
        xdg.configFile."BetterDiscord/data/stable/custom.css".source = ./_assets/custom.css;
        home.packages = [pkgs.goofcord];
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".config/goofcord"];
      })
    ];
}
