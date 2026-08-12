{den, ...}: {
  den.aspects.cli.templ.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.templ];
  };
}
