{
  den.aspects.cli.ghostty = {
    homeManager = {
      config,
      pkgs,
      ...
    }: let
      ghostty = config.programs.ghostty.package;
    in {
      programs.ghostty = {
        enable = true;
        systemd.enable = true;
      };
      # Plain file instead of programs.ghostty.settings so `mutable on` can link it to the repo.
      xdg.configFile."ghostty/config".source = config.lib.mutableSources.source ./_config/config;
      # HM links the unit but never enables it; start it with the session.
      xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
        "${ghostty}/share/systemd/user/app-com.mitchellh.ghostty.service";
      # Plain `ghostty` becomes the primary instance in the launcher's cgroup when the service is down,
      # stealing com.mitchellh.ghostty so the service fails with Result=protocol. `+new-window` goes through
      # D-Bus, which activates the service. Shadows the packaged entry for xdg-terminal-exec and launchers.
      xdg.dataFile."applications/com.mitchellh.ghostty.desktop".source =
        pkgs.runCommand "ghostty-new-window.desktop" {} ''
          sed 's|^Exec=\(.*/ghostty\) --gtk-single-instance=true|Exec=\1 +new-window|' \
            ${ghostty}/share/applications/com.mitchellh.ghostty.desktop > $out
        '';
    };
  };
}
