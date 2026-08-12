{den, ...}: {
  den.aspects.cli.direnv.homeManager = {config, ...}: {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    home.sessionVariables.DIRENV_LOG_FORMAT = "";
    home.file.".config/direnv/direnv.toml".text = ''
      [global]
      log_format = "-"
      log_filter = "^$"
    '';
    home.persistence."/persist".directories = [".local/share/direnv"];
  };
}
