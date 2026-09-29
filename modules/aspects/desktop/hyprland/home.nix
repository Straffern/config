{den, ...}: {
  den.aspects.desktop.hyprland.homeManager = {config, ...}: {
    xdg.configFile."hypr/hyprland.lua".source = config.lib.mutableSources.link ./_config/hyprland.lua;
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
          allow_token_by_default = true
      }
    '';
  };
}
