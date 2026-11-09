{den, ...}: {
  den.aspects.cli.direnv.homeManager = {
    config,
    lib,
    host,
    ...
  }:
    lib.mkMerge [
      {
        programs.direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
        home.sessionVariables.DIRENV_LOG_FORMAT = "";
        # omp worktrees copy repos already open in omp; trust their .envrc so
        # agents can `direnv exec` them without a manual `direnv allow`.
        home.file.".config/direnv/direnv.toml".text = ''
          [global]
          log_format = "-"
          log_filter = "^$"

          [whitelist]
          prefix = ["${config.home.homeDirectory}/.local/share/omp/wt"]
        '';
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [".local/share/direnv"];
      })
    ];
}
