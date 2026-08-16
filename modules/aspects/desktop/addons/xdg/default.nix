{den, ...}: {
  den.aspects.desktop.addons.xdg = {
    vmSmoke = [
      {
        name = "desktop-portal";
        description = "The desktop portal owns its session bus name";
        phase = "session";
        script = ''
          assert login_user is not None, "desktop portal smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet xdg-desktop-portal.service"))
          machine.succeed(user_command("busctl --user status org.freedesktop.portal.Desktop"))
        '';
      }
    ];

    homeManager = {
      config,
      lib,
      ...
    }: let
      webKeys = [
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xht"
        "application/x-extension-xhtml"
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/chrome"
        "x-scheme-handler/ftp"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ];
      heliumAssociations = lib.genAttrs webKeys (_: ["helium.desktop"]);
      braveAssociations = lib.genAttrs webKeys (_: [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
      ]);
    in {
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
          associations = {
            added =
              heliumAssociations
              // {
                "video/mp4" = ["org.gnome.Totem.desktop"];
                "video/quicktime" = ["org.gnome.Totem.desktop"];
                "video/webm" = ["org.gnome.Totem.desktop"];
                "video/x-matroska" = ["org.gnome.Totem.desktop"];
                "image/gif" = ["org.gnome.Loupe.desktop"];
                "image/png" = ["org.gnome.Loupe.desktop"];
                "image/jpg" = ["org.gnome.Loupe.desktop"];
                "image/jpeg" = ["org.gnome.Loupe.desktop"];
              };
            removed = braveAssociations;
          };
          defaultApplications =
            heliumAssociations
            // {
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
