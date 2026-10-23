{
  den.aspects.cli.romm-add.homeManager = {pkgs, ...}: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "romm-add";
        runtimeInputs = with pkgs; [coreutils findutils gnused igir openssh rsync];
        text = builtins.readFile ./romm-add/romm-add.sh;
      })
    ];
  };
}
