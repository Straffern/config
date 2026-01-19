{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.${namespace}) enabled;
in {
  imports = [./disko.nix ./hardware-configuration.nix];

  ${namespace} = {
    system.boot.bios = enabled;
    system.boot.enable = lib.mkForce false;

    suites = {server.enable = true;};
    # suites.kubernetes = enabled;

    cli.programs.nix-ld = enabled;

    user."1" = {
      name = "alex";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };

  sops.secrets."palantir_ssh_private_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "600";
    path = "/home/" + config.${namespace}.user."1".name + "/.ssh/id_ed25519";
    sopsFile = ../../../secrets.yaml;
  };

  sops.secrets."palantir_ssh_public_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "644";
    path =
      "/home/"
      + config.${namespace}.user."1".name
      + "/.ssh/id_ed25519.pub";
    sopsFile = ../../../secrets.yaml;
  };

  environment.systemPackages = [pkgs.home-manager];

  programs.zsh.enable = true;

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
