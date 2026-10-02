{den, ...}: {
  den.aspects.desktop.hyprland.homeManager = {config, ...}: {
    # The selected desktop shell aspect provides hypr/shell.lua.
    xdg.configFile = {
      "hypr/hyprland.lua".source = config.lib.mutableSources.link ./_config/hyprland.lua;
      "hypr/xdph.conf".text = ''
        screencopy {
            allow_token_by_default = true
        }
      '';
    };
  };
}
