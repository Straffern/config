{den, ...}: {
  den.aspects.cli.network-tools.homeManager = {pkgs, ...}: let
    nr7302-monitor = pkgs.writeShellApplication {
      name = "nr7302-monitor";
      runtimeInputs = with pkgs; [
        coreutils
        gawk
        openssh
      ];
      text = builtins.readFile ./network-tools/nr7302-monitor.sh;
    };
    prt = pkgs.callPackage ./network-tools/_package/prt.nix {};
  in {
    home.packages = with pkgs; [
      tshark
      termshark
      kubeshark
      nr7302-monitor
      prt
    ];
  };
}
