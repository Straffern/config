{den, ...}: {den.aspects.cli.podman.homeManager = {pkgs, ...}: {home.packages = with pkgs; [arion podman podman-compose podman-tui amazon-ecr-credential-helper lazydocker];};}
