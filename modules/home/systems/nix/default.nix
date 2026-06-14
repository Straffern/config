{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.nix;
in {
  options.${namespace}.system.nix = {
    enable = mkEnableOption "Management of nix configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixgl.nixGLIntel
      nix-output-monitor
      nvd
    ];

    systemd.user.startServices = "sd-switch";

    programs = {
      home-manager.enable = true;
    };

    home.sessionVariables = {
      NH_FLAKE = "/home/${config.home.username}/.dotfiles";
    };

    nix = {
      settings = {
        # Inherit substituters/keys from NixOS + Determinate; only add HM-specific extras.
        extra-trusted-substituters = [
          "https://numtide.cachix.org?priority=42"
        ];

        extra-trusted-public-keys = [
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        ];

        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
        use-xdg-base-directories = true;
      };
    };

    news = {
      display = "silent";
      json = lib.mkForce {};
      entries = lib.mkForce [];
    };
  };
}
