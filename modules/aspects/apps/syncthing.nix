{den, ...}: {
  den.aspects.apps.syncthing.homeManager = _: {
    services.syncthing = {
      enable = true;
      tray.enable = true;
      extraOptions = ["--gui-address=127.0.0.1:8384"];
    };
  };
}
