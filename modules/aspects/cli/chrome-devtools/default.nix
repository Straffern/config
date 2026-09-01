{den, ...}: {
  den.aspects.cli.chrome-devtools = {
    includes = [den.aspects.apps.helium];
    homeManager = {
      config,
      pkgs,
      ...
    }: {
      home.packages = [
        (pkgs.callPackage ./_package {
          helium = config.programs.helium.package;
        })
      ];
    };
  };
}
