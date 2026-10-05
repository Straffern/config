{den, ...}: {
  den.aspects.desktop.addons.kanshi = {
    homeManager = {
      config,
      pkgs,
      ...
    }: {
      home.packages = with pkgs; [kanshi];

      services.kanshi = {
        enable = true;
        package = pkgs.kanshi;
        systemdTarget = "graphical-session.target";
      };
      xdg.configFile."kanshi/config".source = config.lib.mutableSources.source ./_config/config;

      systemd.user.services.kanshi = {
        Unit = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          RestartSec = 5;
        };
      };
    };
  };
}
