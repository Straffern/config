{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
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
    version = "unstable-2023-10-03";
    src = pkgs.fetchFromGitHub {
      owner = "artemave";
      repo = "tmux_super_fingers";
      rev = "518044ef78efa1cf3c64f2e693fef569ae570ddd";
      sha256 = "1710pqvjwis0ki2c3mdrp2zia3y3i8g4rl6v42pg9nk4igsz39w8";
    };
  };

  televisionSeshChannel = ''
    # Television channel for sesh session management
    # Upstream: https://github.com/alexpasmantier/television/blob/main/cable/unix/sesh.toml
    [metadata]
    name = "sesh"
    description = "Session manager integrating tmux sessions, zoxide directories, and config paths"
    requirements = ["sesh", "fd"]

    [source]
    command = [
      "sesh list --icons",
      "sesh list -t --icons",
      "sesh list -c --icons",
      "sesh list -z --icons",
      "fd -H -d 2 -t d -E .Trash . ~"
    ]
    ansi = true
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
    description = "Kill selected tmux session"
    command = "tmux kill-session -t '{strip_ansi|split: :1..|join: }'"
    mode = "fork"
  '';
in
{
  options.${namespace}.cli.multiplexers.tmux = {
    enable = mkEnableOption "Tmux multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.sesh
      pkgs.lsof
      pkgs.television
      pkgs.fd
      # for tmux super fingers
      pkgs.python3
    ];

    xdg.configFile."television/cable/sesh.toml".text = televisionSeshChannel;

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
        yank
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
          extraConfig = ''
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
            set -g @continuum-systemd-start-cmd 'start-server'
          '';
        }
      ];
      extraConfig = ''
        set -ag terminal-overrides ",*:RGB"
        set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.local/share/tmux/plugins'
        set -g prefix2 C-b
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
        set-option -g extended-keys on
        set-option -g extended-keys-format csi-u

        # Keybinding model:
        # - Root table keeps only fast pane/window navigation.
        # - Prefix keys enter focused tmux tables for pane/window/resize/move/yank/session actions.
        # - Neovim keeps Alt-h/l, Ctrl-h/j/k/l, Ctrl-u/d, Ctrl-Space, and Ctrl-arrow.
        unbind-key -a -T prefix

        # Root fast paths.
        bind-key -n C-M-h select-pane -L
        bind-key -n C-M-j select-pane -D
        bind-key -n C-M-k select-pane -U
        bind-key -n C-M-l select-pane -R
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
        bind : command-prompt
        bind ? list-keys
        bind C-Space send-prefix
        bind Space run-shell -b ${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.sh
        bind d detach-client
        bind f new-window -e FINGERS_EXTEND= -n super-fingers ${tmux-super-fingers}/share/tmux-plugins/tmux-super-fingers/run.sh
        bind q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"
        bind C-r run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh
        bind C-s run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
        bind p switch-client -T pane
        bind w switch-client -T window
        bind r switch-client -T resize
        bind m switch-client -T move
        bind y switch-client -T yank
        bind s switch-client -T session

        # Pane table.
        bind-key -T pane h select-pane -L
        bind-key -T pane j select-pane -D
        bind-key -T pane k select-pane -U
        bind-key -T pane l select-pane -R
        bind-key -T pane v split-window -h -c "#{pane_current_path}"
        bind-key -T pane s split-window -v -c "#{pane_current_path}"
        bind-key -T pane x kill-pane
        bind-key -T pane z resize-pane -Z
        bind-key -T pane o select-pane -t :.+
        bind-key -T pane f run-shell ${tmux-floax}/share/tmux-plugins/tmux-floax/scripts/floax.sh
        bind-key -T pane F run-shell ${tmux-floax}/share/tmux-plugins/tmux-floax/scripts/menu.sh
        bind-key -T pane q display-message "pane table closed"
        bind-key -T pane Escape display-message "pane table closed"

        # Window table.
        bind-key -T window c new-window -c "#{pane_current_path}"
        bind-key -T window r command-prompt -I "#W" "rename-window -- '%%'"
        bind-key -T window x kill-window
        bind-key -T window h previous-window
        bind-key -T window l next-window
        bind-key -T window H swap-window -t -1 \; select-window -t -1
        bind-key -T window L swap-window -t +1 \; select-window -t +1
        bind-key -T window 1 select-window -t 1
        bind-key -T window 2 select-window -t 2
        bind-key -T window 3 select-window -t 3
        bind-key -T window 4 select-window -t 4
        bind-key -T window 5 select-window -t 5
        bind-key -T window 6 select-window -t 6
        bind-key -T window 7 select-window -t 7
        bind-key -T window 8 select-window -t 8
        bind-key -T window 9 select-window -t 9
        bind-key -T window . command-prompt -T target { move-window -t "%%" }
        bind-key -T window R move-window -r
        bind-key -T window q display-message "window table closed"
        bind-key -T window Escape display-message "window table closed"

        # Resize table stays active until closed.
        bind-key -T resize h resize-pane -L 3 \; switch-client -T resize
        bind-key -T resize j resize-pane -D 3 \; switch-client -T resize
        bind-key -T resize k resize-pane -U 3 \; switch-client -T resize
        bind-key -T resize l resize-pane -R 3 \; switch-client -T resize
        bind-key -T resize H resize-pane -L 10 \; switch-client -T resize
        bind-key -T resize J resize-pane -D 10 \; switch-client -T resize
        bind-key -T resize K resize-pane -U 10 \; switch-client -T resize
        bind-key -T resize L resize-pane -R 10 \; switch-client -T resize
        bind-key -T resize = select-layout even-horizontal \; switch-client -T resize
        bind-key -T resize t select-layout tiled \; switch-client -T resize
        bind-key -T resize q display-message "resize table closed"
        bind-key -T resize Escape display-message "resize table closed"

        # Move/mark table stays active until closed.
        bind-key -T move m select-pane -m \; switch-client -T move
        bind-key -T move M select-pane -M \; switch-client -T move
        bind-key -T move s swap-pane \; switch-client -T move
        bind-key -T move h swap-pane -s "{left-of}" \; switch-client -T move
        bind-key -T move j swap-pane -s "{down-of}" \; switch-client -T move
        bind-key -T move k swap-pane -s "{up-of}" \; switch-client -T move
        bind-key -T move l swap-pane -s "{right-of}" \; switch-client -T move
        bind-key -T move H swap-window -t -1 \; select-window -t -1 \; switch-client -T move
        bind-key -T move L swap-window -t +1 \; select-window -t +1 \; switch-client -T move
        bind-key -T move q display-message "move table closed"
        bind-key -T move Escape display-message "move table closed"

        # Yank/buffer table.
        bind-key -T yank y run-shell -b ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/scripts/copy_line.sh
        bind-key -T yank Y run-shell -b ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/scripts/copy_pane_pwd.sh
        bind-key -T yank [ copy-mode
        bind-key -T yank p paste-buffer
        bind-key -T yank b choose-buffer -Z
        bind-key -T yank l list-buffers
        bind-key -T yank e send-keys "tmux capture-pane -p -S - | nvim -c 'set buftype=nofile' +" Enter
        bind-key -T yank q display-message "yank table closed"
        bind-key -T yank Escape display-message "yank table closed"

        # Session table.
        bind-key -T session s choose-tree -Zs
        bind-key -T session S display-popup -E -w 80% -h 70% -d "#{pane_current_path}" -T "Sesh" "tv sesh"
        bind-key -T session n new-session -c "#{pane_current_path}"
        bind-key -T session r command-prompt -I "#S" "rename-session -- '%%'"
        bind-key -T session x kill-session
        bind-key -T session p switch-client -p
        bind-key -T session N switch-client -n
        bind-key -T session d detach-client
        bind-key -T session L switch-client -l
        bind-key -T session q display-message "session table closed"
        bind-key -T session Escape display-message "session table closed"

        # Status bar
        set-option -g status-position top
        set-option -g status-interval 5
        set-option -g status-left-length 30
        set-option -g status-right-length 50
        set-option -g window-status-separator ""
        set-window-option -g automatic-rename on
        set-window-option -g automatic-rename-format '#{b:pane_current_path}'

        # Terminal-palette-driven theme
        set-option -g status-style "bg=default,fg=default"
        set-option -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
        set-option -g status-right "#[fg=blue]#{?pane_in_mode,COPY ,}#{?client_prefix,PREFIX ,}#{?window_zoomed_flag,ZOOM ,}#[fg=brightblack]#h "
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
        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l

        bind-key -T prefix C-g split-window \
        	"$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      '';
    };
  };
}
