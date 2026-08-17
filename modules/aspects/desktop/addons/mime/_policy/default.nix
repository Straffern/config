{lib}: let
  inherit (lib) genAttrs;

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
  webAssociations = genAttrs webKeys (_: ["helium.desktop"]);
in {
  associations = {
    added =
      webAssociations
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
    removed = genAttrs webKeys (_: [
      "brave-browser.desktop"
      "com.brave.Browser.desktop"
    ]);
  };
  defaultApplications =
    webAssociations
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
      "application/toml" = ["org.gnome.TextEditor.desktop"];
      "text/plain" = ["org.gnome.TextEditor.desktop"];
    };
}
