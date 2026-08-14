{den, ...}: {
  den.aspects.desktop = {
    nautilus = {
      nixos = {
        config,
        pkgs,
        ...
      }: {
        services = {
          gvfs.enable = true;
          udisks2.enable = true;
        };
        environment = {
          sessionVariables = {
            NAUTILUS_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
            NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
          };
          pathsToLink = ["/share/nautilus-python/extensions"];
          systemPackages = with pkgs; [
            ffmpegthumbnailer
            nautilus-open-any-terminal
            nautilus-python
          ];
        };
      };
      homeManager = {pkgs, ...}: {
        home.packages = with pkgs; [
          nautilus
          sushi
        ];
        dconf.settings = {
          "com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
        };
      };
    };
  };
}
