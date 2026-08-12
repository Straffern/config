{den, ...}: {
  den.aspects.apps.trayscale.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.trayscale];
  };
  den.aspects.apps.foliate.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.foliate];
    xdg.configFile."com.github.johnfactotum.Foliate/themes/mocha.json".text = ''
      {
        "label": "Mocha",
        "light": { "fg": "#999999", "bg": "#cccccc", "link": "#666666" },
        "dark": { "fg": "#cdd6f4", "bg": "#1e1e2e", "link": "#E0DCF5" }
      }
    '';
  };
  den.aspects.apps.pavucontrol.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.pavucontrol];
  };
  den.aspects.apps.pwvucontrol.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.pwvucontrol];
  };
  den.aspects.apps.sushi.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.sushi];
  };
  den.aspects.apps.gnome-disk-utility.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.gnome-disk-utility];
  };
  den.aspects.apps.totem.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.totem];
  };
  den.aspects.apps.loupe.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.loupe];
  };
  den.aspects.apps.nautilus.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.nautilus];
  };
}
