{den, ...}: {
  den.aspects.apps.desktop-utilities.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      foliate
      gnome-disk-utility
      loupe
      nautilus
      pavucontrol
      pwvucontrol
      sushi
      totem
      trayscale
    ];
    xdg.configFile."com.github.johnfactotum.Foliate/themes/mocha.json".text = ''
      {
        "label": "Mocha",
        "light": { "fg": "#999999", "bg": "#cccccc", "link": "#666666" },
        "dark": { "fg": "#cdd6f4", "bg": "#1e1e2e", "link": "#E0DCF5" }
      }
    '';
  };
}
