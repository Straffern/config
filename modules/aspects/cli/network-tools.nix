{den, ...}: {den.aspects.cli.network-tools.homeManager = {pkgs, ...}: {home.packages = with pkgs; [tshark termshark kubeshark];};}
