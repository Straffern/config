{
  den.aspects.cli.ghostty = {
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      ghostty = config.programs.ghostty.package;
      # Same translations as kitty.nix: tmux 3.6 cannot receive these modified keys natively.
      sendText = lib.mapAttrsToList (key: seq: "${key}=text:${seq}") {
        "shift+enter" = ''\x1b[13;2u'';
        "ctrl+enter" = ''\x1b[27;5;13~'';
        "ctrl+period" = ''\x1b[46;5u'';
        "ctrl+slash" = ''\x1b[47;5u'';
        # OpenCode session navigation and Which-Key controls.
        "ctrl+alt+b" = ''\x1b[98;7u'';
        "ctrl+alt+d" = ''\x1b[100;7u'';
        "ctrl+alt+e" = ''\x1b[101;7u'';
        "ctrl+alt+f" = ''\x1b[102;7u'';
        "ctrl+alt+g" = ''\x1b[103;7u'';
        "ctrl+alt+n" = ''\x1b[110;7u'';
        "ctrl+alt+p" = ''\x1b[112;7u'';
        "ctrl+alt+u" = ''\x1b[117;7u'';
        "ctrl+alt+y" = ''\x1b[121;7u'';
        "ctrl+alt+bracket_left" = ''\x1b[91;7u'';
        "ctrl+alt+bracket_right" = ''\x1b[93;7u'';
        "ctrl+alt+shift+k" = ''\x1b[107;8u'';
        "ctrl+alt+shift+p" = ''\x1b[112;8u'';
        "ctrl+alt+arrow_left" = ''\x1b[1;7D'';
        "ctrl+alt+arrow_right" = ''\x1b[1;7C'';
        "ctrl+alt+arrow_up" = ''\x1b[1;7A'';
        "ctrl+alt+arrow_down" = ''\x1b[1;7B'';
        "ctrl+alt+page_up" = ''\x1b[5;7~'';
        "ctrl+alt+page_down" = ''\x1b[6;7~'';
        "ctrl+alt+home" = ''\x1b[1;7H'';
        "ctrl+alt+end" = ''\x1b[1;7F'';
      };
    in {
      # HM links the unit but never enables it; start it with the session.
      xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
        "${ghostty}/share/systemd/user/app-com.mitchellh.ghostty.service";
      # Plain `ghostty` becomes the primary instance in the launcher's cgroup when the service is down,
      # stealing com.mitchellh.ghostty so the service fails with Result=protocol. `+new-window` goes through
      # D-Bus, which activates the service. Shadows the packaged entry for xdg-terminal-exec and launchers.
      xdg.dataFile."applications/com.mitchellh.ghostty.desktop".source =
        pkgs.runCommand "ghostty-new-window.desktop" {} ''
          sed 's|^Exec=\(.*/ghostty\) --gtk-single-instance=true|Exec=\1 +new-window|' \
            ${ghostty}/share/applications/com.mitchellh.ghostty.desktop > $out
        '';
      programs.ghostty = {
        enable = true;
        # Daemon via systemd + single instance: new windows open instantly.
        systemd.enable = true;
        settings = {
          command = "zsh";
          # Optional include; noctalia renders it when present.
          config-file = "?themes/noctalia";
          font-size = 14;
          window-padding-x = 10;
          window-padding-y = 10;
          # Matches the 0.84 compositor rule kitty/foot get; cells keeps tmux-painted bg translucent too.
          background-opacity = 0.84;
          background-opacity-cells = true;
          window-decoration = "none";
          gtk-single-instance = true;
          quit-after-last-window-closed = false;
          confirm-close-surface = false;
          resize-overlay = "never";
          # tmux owns scrollback; keep ghostty's small (bytes).
          scrollback-limit = 10000000;
          copy-on-select = "clipboard";
          clipboard-read = "ask";
          clipboard-write = "allow";
          mouse-hide-while-typing = true;
          # tmux sets titles/cwd; skip cursor-shape override so nvim/tmux control it.
          shell-integration-features = "no-cursor,sudo,title";
          # Ghostty splits/tabs collide with tmux and OMP shortcuts (ctrl+shift+o/x/e).
          keybind =
            ["ctrl+shift+o=unbind" "ctrl+shift+e=unbind" "ctrl+shift+x=unbind"]
            ++ sendText;
        };
      };
    };
  };
}
