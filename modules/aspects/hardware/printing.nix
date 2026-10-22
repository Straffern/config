{den, ...}: {
  den.aspects.hardware.printing = {
    includes = [den.aspects.network.avahi];

    nixos = _: {
      services.printing = {
        enable = true;
        startWhenNeeded = true;
        browsed.enable = false;
        webInterface = true;
      };

      programs.system-config-printer.enable = true;
    };
  };
}
