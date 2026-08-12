{
  den,
  inputs,
  ...
}: let
  kitty-same-cwd = pkgs:
    pkgs.writeShellApplication {
      name = "kitty-same-cwd";
      runtimeInputs = with pkgs; [jq kitty procps];
      text = ''
        # Get CWD from focused kitty window and open new kitty there
        # Requires: hyprctl (from Hyprland), kitty remote control enabled

        FOCUSED=$(hyprctl activewindow -j 2>/dev/null)

        if [[ -z "$FOCUSED" || "$FOCUSED" == "null" ]]; then
          kitty &
          exit 0
        fi

        FOCUSED_CLASS=$(echo "$FOCUSED" | jq -r '.class // empty')
        FOCUSED_PID=$(echo "$FOCUSED" | jq -r '.pid // empty')

        if [[ "$FOCUSED_CLASS" == "kitty" && -n "$FOCUSED_PID" ]]; then
          CWD=$(kitty @ --to unix:/tmp/kitty ls 2>/dev/null | \
            jq -r --argjson pid "$FOCUSED_PID" \
            '[.[] | .tabs[]? | .windows[]? | select(.foreground_processes[]?.pid == $pid or .pid == $pid)] | .[0].cwd // empty' 2>/dev/null)

          if [[ -z "$CWD" || ! -d "$CWD" ]]; then
            CHILD_PID=$(pgrep -P "$FOCUSED_PID" 2>/dev/null | head -1)
            if [[ -n "$CHILD_PID" ]]; then
              CWD=$(readlink "/proc/$CHILD_PID/cwd" 2>/dev/null)
            fi
          fi

          if [[ -z "$CWD" || ! -d "$CWD" ]]; then
            CWD=$(readlink "/proc/$FOCUSED_PID/cwd" 2>/dev/null)
          fi

          if [[ -n "$CWD" && -d "$CWD" ]]; then
            kitty --directory "$CWD" &
          else
            kitty &
          fi
        else
          kitty &
        fi
      '';
      meta = with pkgs.lib; {
        description = "Open new kitty terminal in the same directory as the focused kitty window";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };
in {
  den.aspects.cli.kitty = {
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      home.packages = [(kitty-same-cwd pkgs)];
      programs.kitty = {
        enable = true;
        extraConfig =
          ''
            symbol_map U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font Mono

            # kitty-scrollback.nvim
            action_alias kitty_scrollback_nvim kitten ~/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py
            map shift+escape kitty_scrollback_nvim
            map ctrl+shift+escape kitty_scrollback_nvim --config ksb_builtin_last_cmd_output

            # Temporary until tmux kitty keyboard protocol support lands: https://github.com/tmux/tmux/pull/4912
            map shift+enter send_text all \e[13;2u
            map ctrl+enter send_text application \x1b[27;5;13~
            mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output
          ''
          + lib.optionalString config.programs.dank-material-shell.enable ''
            include dank-tabs.conf
            include dank-theme.conf
          '';
        keybindings = {
          "super+j" = "no_op";
          "super+l" = "no_op";
        };
        settings = {
          shell = "zsh";
          background_opacity = lib.mkIf (!config.programs.dank-material-shell.enable) (lib.mkForce 1.0);
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";
          shell_integration = "enabled";
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";
          font_size = lib.mkIf (!config.programs.dank-material-shell.enable) 14;
          bell_path = "${config.xdg.dataHome}/sounds/bell.oga";
          window_padding_width = 10;
          scrollback_lines = 5000;
          show_hyperlink_targets = "yes";
          url_style = "curly";
          underline_hyperlinks = "hover";
          copy_on_select = "clipboard";
          clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask no-append";
          sync_to_monitor = "yes";
          input_delay = 0;
          repaint_delay = 2;
          enable_audio_bell = "yes";
          visual_bell_duration = "0.0";
        };
      };
    };

    packages = {pkgs, ...}: {
      kitty-same-cwd = kitty-same-cwd pkgs;
    };
  };
}
