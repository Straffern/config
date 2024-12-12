{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.gpg-agent;
in {
  options.${namespace}.services.gpg-agent = {
    enable = mkEnableOption "Gpg-agent";
  };

  config = mkIf cfg.enable {
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };
  };
}
