{den, ...}: {
  den.aspects.desktop.hyprland.homeManager = {
    config,
    lib,
    ...
  }: {
    # DMS rewrites its fragments in place (`cat >`, os.WriteFile), so edits through these links land in the repo.
    xdg.configFile =
      {
        "hypr/hyprland.lua".source = config.lib.mutableSources.link ./_config/hyprland.lua;
        "hypr/xdph.conf".text = ''
          screencopy {
              allow_token_by_default = true
          }
        '';
      }
      // lib.genAttrs (map (name: "hypr/dms/${name}.lua") ["binds-user" "layout" "outputs" "cursor" "windowrules"]) (
        target: {source = config.lib.mutableSources.link (./_config + "/${lib.removePrefix "hypr/" target}");}
      );
  };
}
