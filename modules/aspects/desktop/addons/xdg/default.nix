{den, ...}: {
  den.aspects.desktop.addons.xdg = {
    homeManager = {
      config,
      lib,
      ...
    }: {
      home.sessionVariables = {
        HISTFILE = lib.mkForce "${config.xdg.stateHome}/bash/history";
        #GNUPGHOME = lib.mkForce "${config.xdg.dataHome}/gnupg";
        GTK2_RC_FILES = lib.mkForce "${config.xdg.configHome}/gtk-2.0/gtkrc";
      };

      xdg = {
        enable = true;
        cacheHome = config.home.homeDirectory + "/.local/cache";

        mimeApps = {
          enable = true;
          associations.added = {
            "video/mp4" = ["org.gnome.Totem.desktop"];
            "video/quicktime" = ["org.gnome.Totem.desktop"];
            "video/webm" = ["org.gnome.Totem.desktop"];
            "video/x-matroska" = ["org.gnome.Totem.desktop"];
            "image/gif" = ["org.gnome.Loupe.desktop"];
            "image/png" = ["org.gnome.Loupe.desktop"];
            "image/jpg" = ["org.gnome.Loupe.desktop"];
            "image/jpeg" = ["org.gnome.Loupe.desktop"];
          };
          defaultApplications = {
            "application/x-extension-htm" = ["helium.desktop"];
            "application/x-extension-html" = ["helium.desktop"];
            "application/x-extension-shtml" = ["helium.desktop"];
            "application/x-extension-xht" = ["helium.desktop"];
            "application/x-extension-xhtml" = ["helium.desktop"];
            "application/xhtml+xml" = ["helium.desktop"];
            "text/html" = ["helium.desktop"];
            "x-scheme-handler/about" = ["helium.desktop"];
            "x-scheme-handler/chrome" = ["helium.desktop"];
            "x-scheme-handler/ftp" = ["helium.desktop"];
            "x-scheme-handler/http" = ["helium.desktop"];
            "x-scheme-handler/https" = ["helium.desktop"];
            "x-scheme-handler/unknown" = ["helium.desktop"];

            "audio/*" = ["mpv.desktop"];
            "video/*" = ["org.gnome.Totem.desktop"];
            "video/mp4" = ["org.gnome.Totem.desktop"];
            "video/x-matroska" = ["org.gnome.Totem.desktop"];
            "image/*" = ["org.gnome.loupe.desktop"];
            "image/png" = ["org.gnome.loupe.desktop"];
            "image/jpg" = ["org.gnome.loupe.desktop"];
            "application/json" = ["gnome-text-editor.desktop"];
            "application/pdf" = ["helium.desktop"];
            "application/x-gnome-saved-search" = ["org.gnome.Nautilus.desktop"];
            "x-scheme-handler/discord" = ["discord.desktop"];
            "x-scheme-handler/tg" = ["telegramdesktop.desktop"];
            "application/toml" = "org.gnome.TextEditor.desktop";
            "text/plain" = "org.gnome.TextEditor.desktop";
          };
        };

        userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
          extraConfig = {
            SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
          };
        };
      };
    };
  };
}
