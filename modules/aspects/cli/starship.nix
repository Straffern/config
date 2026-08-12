{den, ...}: {
  den.aspects.cli.starship.homeManager = {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        command_timeout = 2000;
        scan_timeout = 100;
      };
    };
  };
}
