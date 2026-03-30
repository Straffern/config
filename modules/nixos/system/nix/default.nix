{
  lib,
  config,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.nix;
in {
  options.${namespace}.system.nix = {
    enable = mkEnableOption "Manage of nix configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nil
      nixfmt
      nix-index
      nix-prefetch-git
    ];

    nix = {
      settings = {
        trusted-users = ["@wheel" "root"];
        auto-optimise-store = lib.mkDefault true;
        use-xdg-base-directories = true;
        experimental-features = ["pipe-operators"];
        warn-dirty = false;
        system-features = ["kvm" "big-parallel" "nixos-test"];

        # Cache/query performance
        connect-timeout = 15;
        stalled-download-timeout = 30;
        download-attempts = 2;
        http-connections = 128;
        max-substitution-jobs = 128;
        fallback = true;
        narinfo-cache-negative-ttl = 21600;

        # Binary caches
        substituters = [
          "https://cache.nixos.org"
          "https://devenv.cachix.org?priority=41"
          "https://nix-community.cachix.org?priority=42"
          "https://hyprland.cachix.org?priority=43"
          "https://attic.xuyh0120.win/lantian?priority=44"

          # cachyos nixos-kernel
          "https://cache.garnix.io?priority=50"
          # "https://hyprland-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="

          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          # "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSXnmE="
        ];
      };
      # gc = {
      #   automatic = true;
      #   dates = "weekly";
      #   options = "--delete-older-than 15d";
      # };

      # flake-utils-plus
      generateRegistryFromInputs = true;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };

    # settings = {
    #   experimental-features = "nix-command flakes";
    #   http-connections = 50;
    #   warn-dirty = false;
    #   log-lines = 50;
    #   sandbox = "relaxed";
    #   auto-optimise-store = true;
    #   trusted-users = users;
    #   allowed-users = users;
    # } // (lib.optionalAttrs config.apps.tools.direnv.enable {
    #   keep-outputs = true;
    #   keep-derivations = true;
    # });
  };
}
