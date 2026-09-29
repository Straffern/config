{den, ...}: {
  den.aspects.desktop.hyprland.homeManager = {config, ...}: {
    xdg.configFile."hypr/hyprland.lua".source = config.lib.mutableSources.link ./_config/hyprland.lua;
  };
}
