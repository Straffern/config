{den, ...}: {
  den.aspects.apps.firefox.homeManager = {config, ...}: {
    home.persistence."/persist".directories = [
      ".librewolf"
      ".cache/librewolf"
    ];
    programs.librewolf.enable = true;
  };
}
