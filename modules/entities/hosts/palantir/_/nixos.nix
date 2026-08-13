{
  config,
  lib,
  ...
}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  sops.secrets.ssh_private_key = {
    owner = config.users.users.alex.name;
    group = "users";
    mode = "600";
    path = "${config.users.users.alex.home}/.ssh/id_ed25519";
    sopsFile = ../../../../../secrets/hosts/palantir.yaml;
  };
  sops.secrets.ssh_public_key = {
    owner = config.users.users.alex.name;
    group = "users";
    mode = "644";
    path = "${config.users.users.alex.home}/.ssh/id_ed25519.pub";
    sopsFile = ../../../../../secrets/hosts/palantir.yaml;
  };
  programs.zsh.enable = true;
}
