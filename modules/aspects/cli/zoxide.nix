{den, ...}: {
  den.aspects.cli.zoxide.homeManager = {
    host,
    lib,
    ...
  }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".local/share/zoxide"];
    };
}
