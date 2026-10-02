{den, ...}: {
  den.aspects.hardware.printing = {
    includes = [den.aspects.network.avahi];

    nixos = {pkgs, ...}: {
      services.printing = {
        enable = true;
        startWhenNeeded = true;
        browsed.enable = false;
        webInterface = true;
        drivers = [
          pkgs.gutenprint
        ];
      };

      programs.system-config-printer.enable = true;
    };
  };
}
