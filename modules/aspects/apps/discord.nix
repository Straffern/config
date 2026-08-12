{den, ...}: {
  den.aspects.apps.discord.homeManager = {
    config,
    pkgs,
    ...
  }: {
    xdg.configFile."BetterDiscord/data/stable/custom.css".source = ./_discord/custom.css;
    home = {
      packages = [pkgs.goofcord];
      persistence."/persist".directories = [".config/goofcord"];
    };
  };
}
