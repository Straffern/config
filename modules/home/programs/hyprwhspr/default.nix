{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.programs.hyprwhspr;

  # Custom packages with proper GPU support and pywhispercpp
  customPyWhisperCpp =
    pkgs.${namespace}.pywhispercpp.override {gpuSupport = cfg.gpuSupport;};
  customHyprwhspr =
    pkgs.${namespace}.hyprwhspr.override {pywhispercpp = customPyWhisperCpp;};
in {
  options.${namespace}.programs.hyprwhspr = {
    enable = mkEnableOption "Enable hyprwhspr speech-to-text";

    gpuSupport = mkOption {
      type = types.enum ["vulkan" "rocm" "none"];
      default = "vulkan";
      description = "GPU acceleration backend for local Whisper";
    };
  };

  # Configuration is managed via hyprwhspr CLI:
  #   hyprwhspr setup          - Interactive initial setup
  #   hyprwhspr config edit    - Edit config in $EDITOR
  #   hyprwhspr model download - Download whisper models
  #   hyprwhspr waybar install - Add waybar integration

  config = mkIf cfg.enable {
    # Install packages
    home.packages = [customHyprwhspr pkgs.ydotool pkgs.libnotify];

    # hyprwhspr daemon service
    systemd.user.services.hyprwhspr = {
      Unit = {
        Description = "hyprwhspr speech-to-text daemon";
        After = ["graphical-session.target" "pipewire.service" "ydotool.service"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${customHyprwhspr}/bin/hyprwhspr-daemon";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
