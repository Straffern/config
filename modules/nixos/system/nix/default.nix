{ lib, config, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) mkOpt types;
  cfg = config.${namespace}.system.nix;
in {
  options.${namespace}.system.nix = {
    enable = mkEnableOption "Manage of nix configuration.";
    package =
      mkOpt types.package pkgs.nixVersions.latest "Which nix package to use.";
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
        trusted-users = [ "@wheel" "root" ];
        auto-optimise-store = lib.mkDefault true;
        use-xdg-base-directories = true;
        experimental-features = [ "nix-command" "flakes" ];
        warn-dirty = false;
        system-features = [ "kvm" "big-parallel" "nixos-test" ];
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
