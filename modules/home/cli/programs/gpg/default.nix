{
  pkgs,
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.gpg;
in {
  # TODO: add sshKeys option
  options.${namespace}.cli.programs.gpg = {
    enable = mkEnableOption "GPG";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.seahorse];

    services.gnome-keyring = {
      enable = true;
      components = [
        "secrets"
        "pkcs11"
      ];
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = false;
      enableExtraSocket = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };

    programs = {
      gpg = {
        enable = true;
        #homedir = "${config.xdg.dataHome}/gnupg";
      };
    };

    ${namespace}.system.persistence.directories = [
      ".gnupg"
      ".local/share/keyrings"
    ];
  };
}
