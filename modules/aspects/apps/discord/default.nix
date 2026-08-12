{den, ...}: {
  den.aspects.apps.discord.homeManager = {
    config,
    pkgs,
    ...
  }: {
    xdg.configFile."BetterDiscord/data/stable/custom.css".source = ./_assets/custom.css;
    home = {
      packages = [pkgs.goofcord];
      persistence."/persist".directories = [".config/goofcord"];
    };
  };
}
