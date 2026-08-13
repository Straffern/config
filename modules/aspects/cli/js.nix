{den, ...}: {
  den.aspects.cli.js.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      bun
      nodejs_24
    ];
  };
}
