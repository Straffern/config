{den, ...}: {
  den.aspects.desktop.nautilus = {
    nixos = {
      config,
      lib,
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
          GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
          ]);
        };
        pathsToLink = ["/share/nautilus-python/extensions"];
        systemPackages = with pkgs; [
          ffmpegthumbnailer
          gst_all_1.gst-libav
          nautilus-open-any-terminal
          nautilus-python
        ];
      };
    };
    homeManager.dconf.settings = {
      "com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
    };
  };
}
