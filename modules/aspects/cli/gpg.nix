{den, ...}: {
  den.aspects.cli.gpg.homeManager = {
    config,
    pkgs,
    ...
  }: {
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
    programs.gpg.enable = true;
    home.persistence."/persist".directories = [
      ".gnupg"
      ".local/share/keyrings"
    ];
  };
}
