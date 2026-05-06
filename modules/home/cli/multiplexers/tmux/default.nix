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
in {
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
          plugin = mkTmuxPlugin {
            pluginName = "tmux-super-fingers";
            version = "unstable-2023-10-03";
            src = pkgs.fetchFromGitHub {
              owner = "artemave";
              repo = "tmux_super_fingers";
              rev = "518044ef78efa1cf3c64f2e693fef569ae570ddd";
              sha256 = "1710pqvjwis0ki2c3mdrp2zia3y3i8g4rl6v42pg9nk4igsz39w8";
            };
          };
          extraConfig = ''
            set -g @super-fingers-key f
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux.nvim";
            version = "unstable-2024-02-12";
            src = pkgs.fetchFromGitHub {
              owner = "aserowy";
              repo = "tmux.nvim";
              rev = "9c02adf16ff2f18c8e236deba91e9cf4356a02d2";
              sha256 = "0lg3zcyd76qfbz90i01jwhxfglsnmggynh6v48lnbz0kj1prik4y";
            };
          };
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

        # Change splits to match nvim and easier to remember
        # Open new split at cwd of current split
        unbind %
        unbind '"'
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind h split-window -v -c "#{pane_current_path}"
        bind v split-window -h -c "#{pane_current_path}"
        bind x kill-pane

        # Use vim keybindings in copy mode
        set-window-option -g mode-keys vi

        # v in copy mode starts making selection
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # Escape turns on copy mode
        bind Escape copy-mode

        # Omarchy-style tmux controls
        bind q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"
        bind r command-prompt -I "#W" "rename-window -- '%%'"
        bind c new-window -c "#{pane_current_path}"
        bind k kill-window
        bind R command-prompt -I "#S" "rename-session -- '%%'"
        bind C new-session -c "#{pane_current_path}"
        bind K kill-session
        bind P switch-client -p
        bind N switch-client -n

        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5
        bind -n M-6 select-window -t 6
        bind -n M-7 select-window -t 7
        bind -n M-8 select-window -t 8
        bind -n M-9 select-window -t 9
        bind -n M-Left select-window -t -1
        bind -n M-Right select-window -t +1
        bind -n M-S-Left swap-window -t -1 \; select-window -t -1
        bind -n M-S-Right swap-window -t +1 \; select-window -t +1
        bind -n M-Up switch-client -p
        bind -n M-Down switch-client -n

        bind S display-popup -E -w 80% -h 70% -d "#{pane_current_path}" -T "Sesh" "tv sesh"

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

        # make Prefix p paste the buffer.
        unbind p
        bind p paste-buffer

        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        bind-key e send-keys "tmux capture-pane -p -S - | nvim -c 'set buftype=nofile' +" Enter

        # '@pane-is-vim' is a pane-local option that is set by the plugin on load,
        # and unset when Neovim exits or suspends; note that this means you'll probably
        # not want to lazy-load smart-splits.nvim, as the variable won't be set until
        # the plugin is loaded

        # Smart pane switching with awareness of Neovim splits.
        bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
        bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
        bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
        bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

        # Smart pane resizing with awareness of Neovim splits.
        bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h' 'resize-pane -L 3'
        bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j' 'resize-pane -D 3'
        bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k' 'resize-pane -U 3'
        bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l' 'resize-pane -R 3'

        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l        # Bind Keys
        bind-key -T prefix C-g split-window \
        	"$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      '';
    };
  };
}
