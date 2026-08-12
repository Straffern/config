{den, ...}: {
  den.aspects.desktop.addons.gammastep = {
    homeManager = {lib, ...}: {
      services.gammastep = {
        enable = true;
        provider = "geoclue2";
        temperature = {
          day = 6000;
          night = 4600;
        };
        settings = {general.adjustment-method = "wayland";};
      };
    };
  };
}
