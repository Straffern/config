{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.multiplexers.tmux;

  tmux-floax = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-floax";
    rtpFilePath = "floax.tmux";
    version = "2026-02-24";
    src = pkgs.fetchFromGitHub {
      owner = "omerxx";
      repo = "tmux-floax";
      rev = "133f526793d90d2caa323c47687dd5544a2c704b";
      sha256 = "sha256-9Hb9dn2qHF6KcIhtogvycX3Z0MoQrLPLCzZXtjGlPHw=";
    };
  };

  tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-super-fingers";
    version = "unstable-2026-04-23";
    src = pkgs.fetchFromGitHub {
      owner = "artemave";
      repo = "tmux_super_fingers";
      rev = "523dc9b7a79f1ceb8d9be72e22c263c4a7cd3bdf";
      sha256 = "sha256-GiOkSADuWz19ndsVlKiKatPnplUpmukoZTPakIXWqF0=";
    };
  };

  televisionSeshChannel = ''
    # Television channel for sesh session management
    # Upstream: https://github.com/alexpasmantier/television/blob/main/cable/unix/sesh.toml
    # https://github.com/joshmedeski/sesh
    [metadata]
    name = "sesh"
    description = "Session manager integrating tmux sessions, zoxide directories, and config paths"
    requirements = ["sesh", "fd"]

    [source]
    # Multiple source commands for cycling through different modes
    # Press Ctrl+S to cycle between sources
    command = [
      { name = "All",         run = "sesh list --icons" },
      { name = "Tmux",        run = "sesh list -t --icons" },
      { name = "Configs",     run = "sesh list -c --icons" },
      { name = "Zoxide",      run = "sesh list -z --icons" },
      { name = "Directories", run = "fd -H -d 2 -t d -E .Trash . ~" },
    ]
    ansi = true
    frecency = false # handled by sesh
    no_sort = true # handled by sesh
    output = "{strip_ansi|split: :1..|join: }"

    [preview]
    command = "sesh preview '{strip_ansi|split: :1..|join: }'"

    [keybindings]
    enter = "actions:connect"
    ctrl-d = ["actions:kill_session", "reload_source"]

    [actions.connect]
    description = "Connect to selected session"
    command = "sesh connect '{strip_ansi|split: :1..|join: }'"
    mode = "execute"

    [actions.kill_session]
    description = "Kill selected tmux session (press Ctrl+r to reload)"
    command = "tmux kill-session -t '{strip_ansi|split: :1..|join: }'"
    mode = "fork"
  '';

  copyCurrentLineScript = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    tmux=${pkgs.tmux}/bin/tmux
    remote_shell_wait_time=0.4

    get_tmux_option() {
      local option="$1"
      local default_value="$2"
      local value
      value="$($tmux show-option -gqv "$option")"
      if [[ -z "$value" ]]; then
        printf '%s\n' "$default_value"
      else
        printf '%s\n' "$value"
      fi
    }

    shell_mode() {
      get_tmux_option "@shell_mode" "emacs"
    }

    go_to_beginning_of_current_line() {
      if [[ "$(shell_mode)" == "emacs" ]]; then
        $tmux send-keys 'C-a'
      else
        $tmux send-keys 'Escape' '0'
      fi
    }

    add_sleep_for_remote_shells() {
      local pane_command
      pane_command="$($tmux display-message -p '#{pane_current_command}')"
      if [[ "$pane_command" =~ (ssh|mosh) ]]; then
        sleep "$remote_shell_wait_time"
      fi
    }

    start_tmux_selection() {
      $tmux send-keys -X begin-selection
    }

    end_of_line_in_copy_mode() {
      $tmux send-keys -X -N 150 cursor-down
      $tmux send-keys -X end-of-line
      $tmux send-keys -X previous-word
      $tmux send-keys -X next-word-end
    }

    go_to_end_of_current_line() {
      if [[ "$(shell_mode)" == "emacs" ]]; then
        $tmux send-keys 'C-e'
      else
        $tmux send-keys '$' 'a'
      fi
    }

    go_to_beginning_of_current_line
    add_sleep_for_remote_shells
    $tmux copy-mode
    start_tmux_selection
    end_of_line_in_copy_mode
    $tmux send-keys -X copy-selection-and-cancel
    go_to_end_of_current_line
    $tmux display-message 'Line copied to clipboard!'
  '';
in {
  options.${namespace}.cli.multiplexers.tmux = {
    enable = mkEnableOption "Tmux multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.sesh
      pkgs.lsof
      pkgs.fd
      pkgs.file
      # for tmux super fingers
      pkgs.python3
    ];

    xdg.configFile."television/cable/sesh.toml" =
      mkIf config.${namespace}.cli.programs.television.enable
      {
        text = televisionSeshChannel;
      };

    xdg.configFile."tmux/scripts/copy-current-line.sh" = {
      text = copyCurrentLineScript;
      executable = true;
    };

    programs.tmux = {
      enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "tmux-256color";
      historyLimit = 100000;
      keyMode = "vi";
      prefix = "C-Space";
      sensibleOnTop = true;
      mouse = true;

      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        tmux-thumbs
        {
          plugin = tmux-floax;
          extraConfig = ''
            set -g @floax-bind F
            set -g @floax-bind-menu M
            set -g @floax-width 80%
            set -g @floax-height 80%
            set -g @floax-border-color blue
            set -g @floax-text-color blue
            set -g @floax-change-path true
            set -g @floax-session-name scratch
            set -g @floax-title 'FloaX'
          '';
        }
        {
          plugin = tmux-super-fingers;
          extraConfig = ''
            set -g @super-fingers-key f
          '';
        }
        {
          plugin = resurrect;
          extraConfig =
            ''
              set -g @resurrect-strategy-vim 'session'
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-capture-pane-contents 'on'
            ''
            + ''
              # Taken from: https://github.com/p3t33/nixos_flake/blob/5a989e5af403b4efe296be6f39ffe6d5d440d6d6/home/modules/tmux.nix
              resurrect_dir="$XDG_CACHE_HOME/.tmux/resurrect"
              set -g @resurrect-dir $resurrect_dir

              set -g @resurrect-hook-post-save-all 'target=$(readlink -f $resurrect_dir/last); sed "s| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/home/$USER/.nix-profile/bin/||g" $target | sponge $target'
            '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
            # set -g @continuum-systemd-start-cmd 'start-server'
          '';
        }
      ];
      extraConfig = ''
        set -ag terminal-overrides ",*:RGB"
        # Minimal baseline: tmux already gives xterm* terminals OSC52 clipboard support.
        # Re-enable if Kitty modified keys like Shift+Enter regress inside tmux.
        # set-option -as terminal-features ',xterm-kitty*:extkeys'
        set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.local/share/tmux/plugins'
        bind C-Space send-prefix
        set -sg escape-time 10
        set-option -g set-titles on
        set-option -g set-titles-string "#S / #W"

        # Safe defaults aligned with common tmux/Omarchy ergonomics
        set-option -g base-index 1
        set-option -g pane-base-index 1
        set-option -g renumber-windows on
        set-option -g detach-on-destroy off
        set-option -g focus-events on
        set-option -g set-clipboard on
        set-window-option -g aggressive-resize on

        set -g default-terminal "tmux-256color"
        set -g extended-keys on
        set -g extended-keys-format csi-u

        # jj change IDs use reverse-hex digits k-z, rendered as short prefixes in prompts/logs.
        # tmux-thumbs already matches git SHAs; this makes jj IDs like "rzrzslqw" selectable too.
        set -g @thumbs-regexp-1 '\b[k-z]{8,}\b'
        set -g @thumbs-position right
        set -g @thumbs-contrast 1
        set -g @thumbs-osc52 0
        set -g @thumbs-command 'tmux set-buffer -w -- "{}" && tmux display-message "Copied {}"'
        set -g @thumbs-upcase-command 'tmux set-buffer -w -- "{}" && tmux paste-buffer && tmux display-message "Copied {}"'

        # Keybinding model:
        # - Root table keeps only fast pane/window navigation.
        # - Prefix keys enter focused tmux tables for pane/window/resize/move/yank/session actions.
        # - Neovim keeps Alt-h/l, Ctrl-h/j/k/l, Ctrl-u/d, Ctrl-Space, and Ctrl-arrow.
        unbind-key -a -T prefix

        # Root fast paths.
        bind-key -n C-M-h select-pane -Z -L
        bind-key -n C-M-j select-pane -Z -D
        bind-key -n C-M-k select-pane -Z -U
        bind-key -n C-M-l select-pane -Z -R
        bind-key -n M-1 select-window -t 1
        bind-key -n M-2 select-window -t 2
        bind-key -n M-3 select-window -t 3
        bind-key -n M-4 select-window -t 4
        bind-key -n M-5 select-window -t 5
        bind-key -n M-6 select-window -t 6
        bind-key -n M-7 select-window -t 7
        bind-key -n M-8 select-window -t 8
        bind-key -n M-9 select-window -t 9


        # Prefix entry points and global tmux utilities.
        bind -N "Tmux: command prompt" : command-prompt
        bind -N "Help: show labeled keymap" ? list-keys -N
        bind -N "Help: show raw keymap" / list-keys
        bind -N "Prefix: send prefix to nested tmux/app" C-Space send-prefix
        bind -N "Hint: tmux-thumbs quick visible text picker" Space run-shell -b ${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.sh
        bind -N "Client: detach from tmux session" d detach-client
        bind -N "Hint: tmux-super-fingers fuzzy file/link picker" f new-window -e FINGERS_EXTEND= -n super-fingers ${tmux-super-fingers}/share/tmux-plugins/tmux-super-fingers/run.sh
        bind -N "Config: reload tmux config" q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"
        bind -N "Resurrect: restore saved tmux state" C-r run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh
        bind -N "Resurrect: save current tmux state" C-s run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
        bind -N "Table: pane actions" p switch-client -T pane
        bind -N "Table: window actions" w switch-client -T window
        bind -N "Table: resize panes" r switch-client -T resize
        bind -N "Table: move, swap, and mark panes/windows" m switch-client -T move
        bind -N "Table: yank, copy mode, and buffers" y switch-client -T yank
        bind -N "Table: session actions" s switch-client -T session
        bind -N "Help: toggle contextual status help line" H if -F "#{==:#{status},on}" "set -g status 2" "set -g status on"

        # Pane table.
        bind-key -T pane -N "Pane: focus left, preserving zoom" h select-pane -Z -L
        bind-key -T pane -N "Pane: focus down, preserving zoom" j select-pane -Z -D
        bind-key -T pane -N "Pane: focus up, preserving zoom" k select-pane -Z -U
        bind-key -T pane -N "Pane: focus right, preserving zoom" l select-pane -Z -R
        bind-key -T pane -N "Pane: split right at current path" v split-window -h -c "#{pane_current_path}"
        bind-key -T pane -N "Pane: split down at current path" s split-window -v -c "#{pane_current_path}"
        bind-key -T pane -N "Pane: kill current pane" x kill-pane
        bind-key -T pane -N "Pane: toggle zoom" z resize-pane -Z
        bind-key -T pane -N "Pane: focus next pane" o select-pane -t :.+
        bind-key -T pane -N "Pane: open FloaX scratch popup" f run-shell ${tmux-floax}/share/tmux-plugins/tmux-floax/scripts/floax.sh
        bind-key -T pane -N "Pane: open FloaX menu" F run-shell ${tmux-floax}/share/tmux-plugins/tmux-floax/scripts/menu.sh
        bind-key -T pane -N "Pane: show table help" ? list-keys -N -T pane
        bind-key -T pane -N "Pane: close table" q switch-client -T root
        bind-key -T pane -N "Pane: close table" Escape switch-client -T root

        # Window table.
        bind-key -T window -N "Window: create at current path" c new-window -c "#{pane_current_path}"
        bind-key -T window -N "Window: rename current window" r command-prompt -I "#W" "rename-window -- '%%'"
        bind-key -T window -N "Window: kill current window" x kill-window
        bind-key -T window -N "Window: previous window" h previous-window
        bind-key -T window -N "Window: next window" l next-window
        bind-key -T window -N "Window: move left" H swap-window -t -1 \; select-window -t -1
        bind-key -T window -N "Window: move right" L swap-window -t +1 \; select-window -t +1
        bind-key -T window -N "Window: select 1" 1 select-window -t 1
        bind-key -T window -N "Window: select 2" 2 select-window -t 2
        bind-key -T window -N "Window: select 3" 3 select-window -t 3
        bind-key -T window -N "Window: select 4" 4 select-window -t 4
        bind-key -T window -N "Window: select 5" 5 select-window -t 5
        bind-key -T window -N "Window: select 6" 6 select-window -t 6
        bind-key -T window -N "Window: select 7" 7 select-window -t 7
        bind-key -T window -N "Window: select 8" 8 select-window -t 8
        bind-key -T window -N "Window: select 9" 9 select-window -t 9
        bind-key -T window -N "Window: move to prompted index" . command-prompt -T target { move-window -t "%%" }
        bind-key -T window -N "Window: renumber windows" R move-window -r
        bind-key -T window -N "Window: show table help" ? list-keys -N -T window
        bind-key -T window -N "Window: close table" q switch-client -T root
        bind-key -T window -N "Window: close table" Escape switch-client -T root

        # Resize table stays active until closed.
        bind-key -T resize -N "Resize: left small, stay in table" h resize-pane -L 3 \; switch-client -T resize
        bind-key -T resize -N "Resize: down small, stay in table" j resize-pane -D 3 \; switch-client -T resize
        bind-key -T resize -N "Resize: up small, stay in table" k resize-pane -U 3 \; switch-client -T resize
        bind-key -T resize -N "Resize: right small, stay in table" l resize-pane -R 3 \; switch-client -T resize
        bind-key -T resize -N "Resize: left large, stay in table" H resize-pane -L 10 \; switch-client -T resize
        bind-key -T resize -N "Resize: down large, stay in table" J resize-pane -D 10 \; switch-client -T resize
        bind-key -T resize -N "Resize: up large, stay in table" K resize-pane -U 10 \; switch-client -T resize
        bind-key -T resize -N "Resize: right large, stay in table" L resize-pane -R 10 \; switch-client -T resize
        bind-key -T resize -N "Resize: even horizontal layout, stay in table" = select-layout even-horizontal \; switch-client -T resize
        bind-key -T resize -N "Resize: tiled layout, stay in table" t select-layout tiled \; switch-client -T resize
        bind-key -T resize -N "Resize: show table help, stay in table" ? list-keys -N -T resize \; switch-client -T resize
        bind-key -T resize -N "Resize: close table" q switch-client -T root
        bind-key -T resize -N "Resize: close table" Escape switch-client -T root

        # Move/mark table stays active until closed.
        bind-key -T move -N "Move: mark current pane, stay in table" m select-pane -m \; switch-client -T move
        bind-key -T move -N "Move: clear marked pane, stay in table" M select-pane -M \; switch-client -T move
        bind-key -T move -N "Move: swap current pane with marked pane, stay in table" s swap-pane \; switch-client -T move
        bind-key -T move -N "Move: swap pane with left neighbor, stay in table" h swap-pane -s "{left-of}" \; switch-client -T move
        bind-key -T move -N "Move: swap pane with lower neighbor, stay in table" j swap-pane -s "{down-of}" \; switch-client -T move
        bind-key -T move -N "Move: swap pane with upper neighbor, stay in table" k swap-pane -s "{up-of}" \; switch-client -T move
        bind-key -T move -N "Move: swap pane with right neighbor, stay in table" l swap-pane -s "{right-of}" \; switch-client -T move
        bind-key -T move -N "Move: move window left, stay in table" H swap-window -t -1 \; select-window -t -1 \; switch-client -T move
        bind-key -T move -N "Move: move window right, stay in table" L swap-window -t +1 \; select-window -t +1 \; switch-client -T move
        bind-key -T move -N "Move: show table help, stay in table" ? list-keys -N -T move \; switch-client -T move
        bind-key -T move -N "Move: close table" q switch-client -T root
        bind-key -T move -N "Move: close table" Escape switch-client -T root

        # Yank/buffer table.
        bind-key -T yank -N "Yank: copy current line" y run-shell -b ${config.xdg.configHome}/tmux/scripts/copy-current-line.sh
        bind-key -T yank -N "Yank: copy pane current directory" Y set-buffer -w -- "#{pane_current_path}" \; display-message "Copied #{pane_current_path}"
        bind-key -T yank -N "Yank: enter tmux copy mode" [ copy-mode
        bind-key -T yank -N "Yank: paste tmux buffer" p paste-buffer
        bind-key -T yank -N "Yank: choose tmux buffer" b choose-buffer -Z
        bind-key -T yank -N "Yank: list tmux buffers" l list-buffers
        bind-key -T yank -N "Yank: capture pane history into nvim" e send-keys "tmux capture-pane -p -S - | nvim -c 'set buftype=nofile' +" Enter
        bind-key -T yank -N "Yank: show table help" ? list-keys -N -T yank
        bind-key -T yank -N "Yank: close table" q switch-client -T root
        bind-key -T yank -N "Yank: close table" Escape switch-client -T root

        # Session table.
        bind-key -T session -N "Session: choose session tree" s choose-tree -Zs
        bind-key -T session -N "Session: open sesh popup" S display-popup -E -w 80% -h 70% -d "#{pane_current_path}" -T "Sesh" "tv sesh"
        bind-key -T session -N "Session: create at current path" n new-session -c "#{pane_current_path}"
        bind-key -T session -N "Session: rename current session" r command-prompt -I "#S" "rename-session -- '%%'"
        bind-key -T session -N "Session: kill current session" x kill-session
        bind-key -T session -N "Session: previous session/client" p switch-client -p
        bind-key -T session -N "Session: next session/client" N switch-client -n
        bind-key -T session -N "Session: detach client" d detach-client
        bind-key -T session -N "Session: last session/client" L switch-client -l
        bind-key -T session -N "Session: show table help" ? list-keys -N -T session
        bind-key -T session -N "Session: close table" q switch-client -T root
        bind-key -T session -N "Session: close table" Escape switch-client -T root

        # Status bar
        set-option -g status on
        set-option -g status-position top
        set-option -g status-interval 5
        set-option -g status-left-length 30
        set-option -g status-right-length 80
        set-option -g window-status-separator ""
        set-window-option -g automatic-rename on
        set-window-option -g automatic-rename-format '#{b:pane_current_path}'

        # Terminal-palette-driven theme
        set-option -g status-style "bg=default,fg=default"
        set-option -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
        set-option -g status-right "#[fg=blue]TABLE:#{client_key_table} #{?pane_in_mode,COPY ,}#{?window_zoomed_flag,ZOOM ,}#[fg=brightblack]#h "
        set-option -g status-format[1] '#[fg=blue,bold]#{client_key_table} #[fg=brightblack]│ #[fg=default]#{?#{==:#{client_key_table},prefix},PREFIX p pane | w window | r resize | m move | y yank | s session | Space thumbs | f fingers | ? labels | / raw | H help,#{?#{==:#{client_key_table},pane},PANE h/j/k/l focus | v split right | s split down | x kill | z zoom | o next | f/F floax | ? help | q close,#{?#{==:#{client_key_table},window},WINDOW c new | r rename | x kill | h/l prev/next | H/L move | 1-9 select | . move index | R renumber | ? help | q close,#{?#{==:#{client_key_table},resize},RESIZE h/j/k/l small | H/J/K/L large | = even | t tiled | ? help | q close,#{?#{==:#{client_key_table},move},MOVE m mark | M clear | s swap marked | h/j/k/l swap pane | H/L move window | ? help | q close,#{?#{==:#{client_key_table},yank},YANK y line | Y cwd | [ copy-mode | p paste | b choose | l list | e capture nvim | ? help | q close,#{?#{==:#{client_key_table},session},SESSION s choose | S sesh | n new | r rename | x kill | p/N prev/next | d detach | L last | ? help | q close,#{?pane_in_mode,COPY v select | C-v rectangle | y copy | C-h/j/k/l pane focus | q/Esc close,ROOT C-M-h/j/k/l pane focus | M-1..9 windows | prefix p/w/r/m/y/s tables | prefix H help}}}}}}}}'
        set-window-option -g window-status-format "#[fg=brightblack] #I:#W "
        set-window-option -g window-status-current-format "#[fg=blue,bold] #I:#W "
        set-option -g pane-border-style "fg=brightblack"
        set-option -g pane-active-border-style "fg=blue"
        set-option -g message-style "bg=default,fg=blue"
        set-option -g message-command-style "bg=default,fg=blue"
        set-option -g mode-style "bg=blue,fg=black"
        set-window-option -g clock-mode-colour blue

        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        # Copy-mode navigation mirrors pane movement without touching Neovim root keys.
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi ! send-keys -X copy-pipe-and-cancel -C 'tr -d "\n" | tmux load-buffer -w -'
        bind-key -T copy-mode-vi 'C-h' select-pane -Z -L
        bind-key -T copy-mode-vi 'C-j' select-pane -Z -D
        bind-key -T copy-mode-vi 'C-k' select-pane -Z -U
        bind-key -T copy-mode-vi 'C-l' select-pane -Z -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l

        bind-key -T prefix C-g split-window \
        	"$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      '';
    };
    # Declarative tmux service replaces tmux-continuum's auto-generated unit.
    # Continuum's systemd_enable.sh writes ~/.config/systemd/user/tmux.service
    # with hardcoded nix-store generation paths that break after GC.
    # With @continuum-boot 'on', continuum skips writing if the unit file already
    # exists (write_unit_file_unless_exists checks [ -e path ]), so HM's symlink
    # takes precedence. Resurrect scripts use absolute Nix store paths.
    systemd.user.services.tmux = {
      # Preserve live sessions across Home Manager applies. ExecStop still
      # saves then kills the server for explicit stops and shutdown.
      Unit = {
        Description = "tmux default session (detached)";
        Documentation = "man:tmux(1)";
        X-SwitchMethod = "keep-old";
      };
      Service = {
        Type = "forking";
        Environment = ["DISPLAY=:0"];
        ExecStart = "${pkgs.tmux}/bin/tmux start-server";
        ExecStop = [
          "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh"
          "${pkgs.tmux}/bin/tmux kill-server"
        ];
        KillMode = "mixed";
        RestartSec = 2;
      };
      Install.WantedBy = ["default.target"];
    };
    # Remove tmux-continuum's stale generated unit if it's a plain file (not
    # HM's symlink). Without this, HM refuses to link the declarative unit.
    home.activation.removeStaleTmuxService = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        tmuxUnit="$HOME/.config/systemd/user/tmux.service"
        if [ -e "$tmuxUnit" ] && [ ! -L "$tmuxUnit" ]; then
          $DRY_RUN_CMD rm -f "$tmuxUnit"
        fi
      '';
    };
  };
}
