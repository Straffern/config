{ pkgs, lib, namespace, ... }:
let
  inherit (lib) makeBinPath;

  # Custom nsxiv for waldl with requested keybindings
  # Build marker: forces rebuild when keybindings change
  nsxiv-waldl = pkgs.nsxiv.overrideAttrs (old: {
    pname = "nsxiv-waldl";
    postPatch = (old.postPatch or "") + ''
      # === THUMBNAIL SIZE ===
      # Sizes: { 32, 64, 96, 128, 160, 256, 512 } - index 5 = 256px (good default for laptop/desktop)
      sed -i 's/static const int thumb_sizes\[\] = { 32, 64, 96, 128, 160 };/static const int thumb_sizes[] = { 32, 64, 96, 128, 160, 256, 512 };/' config.def.h
      sed -i 's/static const int THUMB_SIZE = 3;/static const int THUMB_SIZE = 5;/' config.def.h

      # === KEYBINDINGS ===
      # 1. Change prefix to Space
      sed -i 's/ControlMask,.*XK_x,.*g_prefix_external/0, XK_space, g_prefix_external/' config.def.h

      # 2. Change Enter to quit with success (0) using g_pick_quit
      sed -i 's/0,.*XK_Return,.*g_switch_mode,.*None/0, XK_Return, g_pick_quit, 0/' config.def.h

      # 3. Change q to quit with status 1
      sed -i 's/0,.*XK_q,.*g_quit,.*0/0, XK_q, g_quit, 1/' config.def.h

      # 4. Change BackSpace to quit with status 2
      sed -i 's/0,.*XK_BackSpace,.*i_navigate,.*-1/0, XK_BackSpace, g_quit, 2/' config.def.h

      # 5. Remove original Space binding to avoid conflict
      sed -i '/0,.*XK_space,.*i_navigate/d' config.def.h

      # 6. Ctrl+u = previous page (exit 4) - replaces g_unmark_all
      sed -i 's/ControlMask,.*XK_u,.*g_unmark_all.*/ControlMask, XK_u, g_quit, 4 },/' config.def.h

      # 7. Ctrl+d = next page (exit 3) - add new binding after Ctrl+u line
      sed -i '/ControlMask,.*XK_u,.*g_quit/a\    { ControlMask, XK_d, g_quit, 3 },' config.def.h
    '';
  });

  deps = [
    pkgs.curl
    pkgs.jq
    nsxiv-waldl
    pkgs.rofi
    pkgs.tofi
    pkgs.libnotify
    pkgs.dmenu
    pkgs.imv
    pkgs.socat
  ];

in pkgs.writeShellApplication {
  name = "waldl";
  runtimeInputs = deps;
  text = builtins.readFile ./waldl.sh;

  meta = with lib; {
    description = "A Wallhaven downloader integrated with nsxiv and rofi/tofi";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
