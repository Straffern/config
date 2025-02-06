{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption literalExample;
  cfg = config.${namespace}.cli.programs.ssh;
in {
  options.${namespace}.cli.programs.ssh = {
    enable = mkEnableOption "SSH";

    extraHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "The hostname or IP address of the SSH host.";
          };
          identityFile = lib.mkOption {
            type = lib.types.str;
            description = "The path to the identity file for the SSH host.";
          };
        };
      });
      default = { };
      description = "A set of extra SSH hosts.";
      example = literalExample ''
        {
          "gitlab-personal" = {
            hostname = "gitlab.com";
            identityFile = "~/.ssh/id_ed25519_personal";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.keychain = {
      enable = true;
      keys = [ "id_ed25519" ];
      agents = [ "gpg" "ssh" ];
    };

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      matchBlocks = cfg.extraHosts;
    };
  };
}
