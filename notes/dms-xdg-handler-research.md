# DMS opener and XDG association research

## Scope and source basis

This note records the final ownership model for MIME associations. It keeps the
upstream DMS/XDG evidence and the selected policy, while describing only the
architecture that remains in the repository. The earlier bridge and migration
state machine was completed, then deleted; it is not a supported interface.

## Primary DMS and XDG evidence

The pinned [`dms-open.desktop`](https://github.com/AvengeMedia/DankMaterialShell/blob/8d9c9616051e71ce6e76544f735c1794ebd59339/assets/dms-open.desktop)
uses `Exec=dms open %u`, is `NoDisplay=true`, and advertises five registrations:
`x-scheme-handler/http`, `x-scheme-handler/https`, `x-scheme-handler/dms`,
`text/html`, and `application/xhtml+xml`. The opener dispatches `http://`,
`https://`, and `dms://` requests through the app/browser pickers
([`commands_open.go`](https://github.com/AvengeMedia/DankMaterialShell/blob/8d9c9616051e71ce6e76544f735c1794ebd59339/core/cmd/dms/commands_open.go));
the browser picker excludes `dms-open.desktop` to prevent recursion.

`MimeType` entries have no priority
([Desktop Entry §10](https://specifications.freedesktop.org/desktop-entry/latest-single/#mime-types)).
MIME Applications associations are expressed by `[Default Applications]`,
`[Added Associations]`, and `[Removed Associations]`
([§§3–4](https://specifications.freedesktop.org/mime-apps/latest/associations.html)).
Shared-MIME globs describe type detection, not application ownership
([shared MIME database](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/raw/master/data/freedesktop.org.xml.in)).

DMS's GUI intentionally offers **DMS Chooser** for every non-terminal
default-app category, not just the five desktop-entry registrations. A later
GUI choice may therefore assign DMS Chooser to PDF, image, video, audio, text,
or another supported category. The five entries are the automatic desktop
registration subset, not a complete mutable policy.

The pinned DMS reader consumes the three standard groups and keeps the first
desktop ID in each default value. Its historical writer used direct `0644`
`os.WriteFile`, without temporary-file replacement or `fsync`; write errors
were returned over IPC and only logged by QML. The implementation input was
updated to verified descendant
[`0100c64d7a4ebbb6daef45e666e9670df01f52c5`](https://github.com/AvengeMedia/DankMaterialShell/commit/0100c64d7a4ebbb6daef45e666e9670df01f52c5),
which retains `renderMimeapps` and `atomicWriteFile`. Its writer replaces via
a same-directory temporary file and rename, but does not call `fsync`; this
provides atomic replacement, not crash durability.

## Final ownership model

General XDG configuration is independent of MIME ownership. Declarative MIME
ownership is the optional `den.aspects.desktop.addons.mime` aspect defined at
`modules/aspects/desktop/addons/mime/default.nix`; its DMS-free policy is in
`modules/aspects/desktop/addons/mime/_policy/default.nix`. No profile or host
currently selects this aspect.

When selected, the declarative MIME aspect enables Home Manager's
`xdg.mimeApps` module and creates the config-home and data-home
`mimeapps.list` links. It contains no DMS detection, desktop entries, schemes,
assertions, or activation behavior.

The DMS aspect contains no MIME configuration. It does not import the
declarative policy, set `xdg.mimeApps`, seed or validate `mimeapps.list`, or
assert against the MIME aspect. On Sonic the declarative MIME aspect is absent,
so DMS and its upstream GUI/backend interact with user MIME state without Home
Manager participating. Selecting both ownership approaches would be a
configuration error, but DMS does not encode or enforce that relationship.

## Declarative default policy

The standalone declarative policy uses:

- Helium for all web types and PDF.
- MPV for audio defaults.
- Totem for video defaults and added video associations.
- Loupe for image defaults and added image associations.
- GNOME Text Editor for JSON, TOML, and plain text.
- Nautilus for GNOME saved searches.
- Discord and Telegram for their respective schemes.
- Removed stale Brave desktop IDs for web keys.

The policy contains no DMS desktop ID or `dms` scheme association.

## Primary sources

- [Pinned desktop entry](https://github.com/AvengeMedia/DankMaterialShell/blob/8d9c9616051e71ce6e76544f735c1794ebd59339/assets/dms-open.desktop)
- [Pinned opener](https://github.com/AvengeMedia/DankMaterialShell/blob/8d9c9616051e71ce6e76544f735c1794ebd59339/core/cmd/dms/commands_open.go)
- [Pinned desktop persistence implementation](https://github.com/AvengeMedia/DankMaterialShell/tree/8d9c9616051e71ce6e76544f735c1794ebd59339/core/internal/desktop)
- [Updated upstream writer](https://github.com/AvengeMedia/DankMaterialShell/commit/fb9f00a61616456115c2b63128fb51bba93494ee)
- [Desktop Entry §10](https://specifications.freedesktop.org/desktop-entry/latest-single/#mime-types)
- [MIME Applications §§3–4](https://specifications.freedesktop.org/mime-apps/latest/associations.html)
- [shared MIME database](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/raw/master/data/freedesktop.org.xml.in)
