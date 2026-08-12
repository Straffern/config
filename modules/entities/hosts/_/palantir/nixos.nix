{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  users.users.alex.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
  ];
  networking.hostName = "palantir";
  sops.secrets.ssh_private_key = {
    owner = config.users.users.alex.name;
    group = "users";
    mode = "600";
    path = "/home/${config.users.users.alex.name}/.ssh/id_ed25519";
    sopsFile = ../../../../../secrets/hosts/palantir.yaml;
  };
  sops.secrets.ssh_public_key = {
    owner = config.users.users.alex.name;
    group = "users";
    mode = "644";
    path = "/home/${config.users.users.alex.name}/.ssh/id_ed25519.pub";
    sopsFile = ../../../../../secrets/hosts/palantir.yaml;
  };
  environment.systemPackages = [pkgs.home-manager];
  programs.zsh.enable = true;
}
