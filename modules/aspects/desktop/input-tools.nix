{den, ...}: {
  den.aspects.desktop.input-tools.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      keymapp
      libinput
      showmethekey
    ];
  };
}
