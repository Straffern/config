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
        experimental-features = ["nix-command" "flakes" "parallel-eval"];
        warn-dirty = false;
        system-features = ["kvm" "big-parallel" "nixos-test"];
        eval-cores = 0;

        # Binary caches
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
