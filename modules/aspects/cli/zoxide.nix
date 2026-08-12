{den, ...}: {
  den.aspects.cli.zoxide.homeManager = {config, ...}: {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    home.persistence."/persist".directories = [".local/share/zoxide"];
  };
}
