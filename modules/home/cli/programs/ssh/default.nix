{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption literalExample types;
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
        user = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Specifies the user to log in as.";
        };
        sendEnv = lib.mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Environment variables to send from the local host to the
            server.
          '';
        };

        setEnv = lib.mkOption {
          type = with types; attrsOf (oneOf [ str path int float ]);
          default = { };
          description = ''
            Environment variables and their value to send to the server.
          '';
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
      compression = true;
      extraConfig = ''
        SetEnv TERM=xterm
      '';
    };
  };
}
