{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (pkgs.${namespace}) clipy;

  # Trayscale doesn't respond to SIGTERM, needs D-Bus quit action for graceful shutdown
  trayscaleWithGracefulShutdown = ''
    uwsm app -t service \
      -p TimeoutStopSec=5 \
      -p 'ExecStop=${pkgs.systemdMinimal}/bin/busctl --user call dev.deedles.Trayscale /dev/deedles/Trayscale org.gtk.Actions Activate sava{sv} quit 0 0' \
      -- ${pkgs.trayscale}/bin/trayscale --hide-window
  '';
  # sshHosts = {
  #   "frostmourne" = {
  #     hostname = "%(cat ${config.sops.secrets.frostmourne_ip.path})";
  #     user = "alex";
  #   };
  # };
in {
  programs.zsh.sessionVariables = {
    PATH = "$XDG_BIN_HOME:$HOME/go/bin:$XDG_CACHE_HOME/.bun/bin:$HOME/.npm-global/bin:$PATH";
  };

  asgaard = {
    desktops = {
      hyprland = {
        enable = true;
        execOnceExtras = [
          trayscaleWithGracefulShutdown
          "uwsm app -- ${pkgs.networkmanagerapplet}/bin/nm-applet"
          "uwsm app -- ${pkgs.blueman}/bin/blueman-applet"
        ];
      };
    };

    cli = {
      terminals.alacritty.enable = true;
      programs = {
        lobster.enable = true;
        ai = {
          enable = true;
          opencode = {enable = true;};
          shellFunction = {
            enable = true;
            model = "opencode/grok-code";
            # systemPrompt = "...";  # Custom system prompt
          };
        };
      };
    };
    programs.waldl = {
      enable = true;
      walldir = "/home/alex/.dotfiles/packages/wallpapers/wallpapers";
    };
    suites = {
      desktop.enable = true;
      social.enable = true;
    };
    styles.stylix = {
      wallpaper = pkgs.${namespace}.wallpapers.cat_in_window;
      # patch = {
      #   # contrast = 20;
      #   recolor = false;
      # };
    };
    # styles.stylix.wallpaper = pkgs.${namespace}.wallpapers.osaka-jade-bg;
  };
  wayland.windowManager.hyprland.settings.monitor =
    lib.mkForce "eDP-1, preferred, auto, 1.5";
  sops.secrets.ssh_config = {sopsFile = ../../../secrets.yaml;};

  programs.ssh.includes = [config.sops.secrets.ssh_config.path];

  home.packages = with pkgs; [nwg-displays clipy uv];
  home.stateVersion = "23.11";
}
