{den, ...}: {
  den.aspects.desktop.addons.mime.homeManager = {lib, ...}: {
    xdg.mimeApps =
      import ./_policy {inherit lib;}
      // {
        enable = true;
      };
  };
}
