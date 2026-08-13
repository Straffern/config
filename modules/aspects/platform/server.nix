{den, ...}: {
  den.aspects.platform = {
    headless.nixos = {lib, ...}: {
      environment.variables.BROWSER = "echo";
      environment.stub-ld.enable = lib.mkDefault false;
      documentation = {
        enable = lib.mkDefault false;
        info.enable = lib.mkDefault false;
        man.enable = lib.mkDefault false;
        nixos.enable = lib.mkDefault false;
      };
      fonts.fontconfig.enable = lib.mkDefault false;
    };

    server-runtime.nixos = {lib, ...}: {
      time.timeZone = lib.mkDefault "UTC";
      systemd.tmpfiles.rules = ["L+ /usr/local/bin - - - - /run/current-system/sw/bin/"];
      systemd.settings.Manager = {
        RuntimeWatchdogSec = "20s";
        RebootWatchdogSec = "30s";
      };
    };
  };
}
