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
        trusted-users = [
          "@wheel"
          "root"
        ];
        auto-optimise-store = lib.mkDefault true;
        use-xdg-base-directories = true;
        experimental-features = ["pipe-operators"];
        warn-dirty = false;
        system-features = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];

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
          "https://niri.cachix.org?priority=44"
          "https://attic.xuyh0120.win/lantian?priority=45"

          "https://cache.numtide.com?priority=46"
          # "https://hyprland-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="

          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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
