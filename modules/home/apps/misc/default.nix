{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf types;
  cfg = config.apps.misc;
in {
  options.apps.misc = with types; {
    enable = mkBoolOpt false "Enable or disable misc apps";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Development
      git
      git-remote-gcrypt
      bat
      eza
      fzf
      fd
      zellij

      # Util
      unzip
      sshfs
      bottom
      ffmpeg
      python3
      wl-clipboard

      libinput
    ];
  };
}
