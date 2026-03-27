{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.programs.voxtype;

  voxtypePkg =
    pkgs.${namespace}.voxtype.override {
      inherit (cfg) whisperGpuBackend;
    };
in {
  options.${namespace}.programs.voxtype = {
    enable = mkEnableOption "voxtype push-to-talk voice-to-text";

    whisperGpuBackend = mkOption {
      type = types.enum ["vulkan" "rocm" "none"];
      default = "vulkan";
      description = "GPU backend for whisper.cpp. Affects build — all engines compiled in regardless.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [voxtypePkg];

    # Config is user-managed: voxtype uses built-in defaults when no file exists,
    # then `voxtype setup` guides initial configuration (engine, model, etc.).
    # No Nix-managed config — engine/model switching stays runtime-only.

    systemd.user.services.voxtype = {
      Unit = {
        Description = "VoxType push-to-talk voice-to-text daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "pipewire.service" "pipewire-pulse.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${voxtypePkg}/bin/voxtype daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
