{
  lib,
  pkgs,
  config,
  namespace,
  inputs,
  ...
}: let
  inherit (pkgs.${namespace}) clipy;
  voxtypePkg = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.onnx-rocm;
in {
  programs.zsh.sessionVariables = {
    PATH = "$XDG_BIN_HOME:$HOME/go/bin:$HOME/.npm-global/bin:$PATH:$XDG_CACHE_HOME/.bun/bin";
  };

  asgaard = {
    desktops = {
      niri.enable = true;
      shells.dms.enable = true;
    };

    cli = {
      terminals.alacritty.enable = true;
      programs = {
        lobster.enable = true;
        ai = {
          enable = true;
          opencode.enable = true;
          opencode.server.enable = true;
          opencode.wrapper.enable = true;
          opencode.kittylitter.enable = true;
          opencode.tailscaleServe.enable = true;
          pi.dashboard = {
            enable = true;
            tailscaleServe.enable = true;
          };
          shellFunction = {
            enable = true;
            model = "openai-codex/gpt-5.3-codex-spark";
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
  };
  sops.secrets.ssh_config = {
    sopsFile = ../../../secrets.yaml;
  };

  programs.ssh.includes = [config.sops.secrets.ssh_config.path];

  systemd.user.services.voxtype = {
    Unit = {
      Description = "VoxType push-to-talk voice-to-text daemon";
      Documentation = "https://voxtype.io";
      PartOf = ["graphical-session.target"];
      After = [
        "graphical-session.target"
        "pipewire.service"
        "pipewire-pulse.service"
      ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${voxtypePkg}/bin/voxtype daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = ["graphical-session.target"];
  };

  home.packages = with pkgs; [
    nwg-displays
    clipy
    pkgs.llm-agents.omp
    pkgs.llm-agents.pi
    uv
    v4l-utils
    guvcview
    voxtypePkg
  ];
  home.stateVersion = "26.05";
}
