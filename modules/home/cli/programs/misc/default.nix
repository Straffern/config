{ config, pkgs, lib, namespace, ... }:
let
  inherit (lib) mkIf types;
  cfg = config.${namespace}.cli.programs.misc;
in {
  options.${namespace}.cli.programs.misc = with types; {
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
