{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.security.sops;
in {
  options.${namespace}.security.sops = { enable = mkEnableOption "SOPS"; };

  config = mkIf cfg.enable {
    sops = { age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; };
  };
}
