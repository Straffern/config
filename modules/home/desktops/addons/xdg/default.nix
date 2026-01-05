{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktops.addons.xdg;
in {
  options.${namespace}.desktops.addons.xdg = {
    enable = mkEnableOption "XDG config";
  };

  config = mkIf cfg.enable {
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
          "video/mp4" = [ "org.gnome.Totem.desktop" ];
          "video/quicktime" = [ "org.gnome.Totem.desktop" ];
          "video/webm" = [ "org.gnome.Totem.desktop" ];
          "video/x-matroska" = [ "org.gnome.Totem.desktop" ];
          "image/gif" = [ "org.gnome.Loupe.desktop" ];
          "image/png" = [ "org.gnome.Loupe.desktop" ];
          "image/jpg" = [ "org.gnome.Loupe.desktop" ];
          "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        };
        defaultApplications = {
          "application/x-extension-htm" = [ "brave-browser.desktop" ];
          "application/x-extension-html" = [ "brave-browser.desktop" ];
          "application/x-extension-shtml" = [ "brave-browser.desktop" ];
          "application/x-extension-xht" = [ "brave-browser.desktop" ];
          "application/x-extension-xhtml" = [ "brave-browser.desktop" ];
          "application/xhtml+xml" = [ "brave-browser.desktop" ];
          "text/html" = [ "brave-browser.desktop" ];
          "x-scheme-handler/about" = [ "brave-browser.desktop" ];
          "x-scheme-handler/chrome" = [ "chromium-browser.desktop" ];
          "x-scheme-handler/ftp" = [ "brave-browser.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
          "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];

          "audio/*" = [ "mpv.desktop" ];
          "video/*" = [ "org.gnome.Totem.desktop" ];
          "video/mp4" = [ "org.gnome.Totem.desktop" ];
          "video/x-matroska" = [ "org.gnome.Totem.desktop" ];
          "image/*" = [ "org.gnome.loupe.desktop" ];
          "image/png" = [ "org.gnome.loupe.desktop" ];
          "image/jpg" = [ "org.gnome.loupe.desktop" ];
          "application/json" = [ "gnome-text-editor.desktop" ];
          "application/pdf" = [ "brave-browser.desktop" ];
          "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
          "x-scheme-handler/discord" = [ "discord.desktop" ];
          "x-scheme-handler/spotify" = [ "spotify.desktop" ];
          "x-scheme-handler/tg" = [ "telegramdesktop.desktop" ];
          "application/toml" = "org.gnome.TextEditor.desktop";
          "text/plain" = "org.gnome.TextEditor.desktop";
        };
      };

      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };
  };
}
