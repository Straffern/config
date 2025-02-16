{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.gpg;
in {
  # TODO: add sshKeys option
  options.${namespace}.cli.programs.gpg = { enable = mkEnableOption "GPG"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.seahorse ];

    services.gnome-keyring.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      # sshKeys = [ "CHANGE_ME" ];
      pinentryPackage = pkgs.pinentry-gnome3;
      defaultCacheTtlSsh = 7200;
    };

    programs = {
      gpg = {
        enable = true;
        #homedir = "${config.xdg.dataHome}/gnupg";
      };
    };

    # systemd.user.sockets.gpg-agent = {
    #   listenStreams = let
    #     user = "haseeb";
    #     socketDir =
    #       pkgs.runCommand "gnupg-socketdir" {
    #         nativeBuildInputs = [pkgs.python3];
    #       } ''
    #         python3 ${./gnupgdir.py} '/home/${user}/.local/share/gnupg' > $out
    #       '';
    #   in [
    #     "" # unset
    #     "%t/gnupg/${builtins.readFile socketDir}/S.gpg-agent"
    #   ];
    # };
  };
}
