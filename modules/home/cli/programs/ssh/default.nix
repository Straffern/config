{
  config,
  lib,
  namespace,
  ...
}: let
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
            type = with types; either (listOf str) (nullOr str);
            default = [];
            description = "The path to the identity file for the SSH host.";
          };
          user = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Specifies the user to log in as.";
          };
          sendEnv = lib.mkOption {
            type = types.listOf types.str;
            default = [];
            description = ''
              Environment variables to send from the local host to the
              server.
            '';
          };
          setEnv = lib.mkOption {
            type = with types; attrsOf (oneOf [str path int float]);
            default = {};
            description = ''
              Environment variables and their value to send to the server.
            '';
          };
        };
      });
      default = {};
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
      keys = ["id_ed25519"];
      # agents = [ "gpg" "ssh" ];
      enableZshIntegration = false;
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings =
        lib.mapAttrs (_name: host:
          lib.filterAttrs (_: v: v != null && v != [] && v != {}) {
            HostName = host.hostname;
            User = host.user;
            IdentityFile = host.identityFile;
            SendEnv = host.sendEnv;
            SetEnv = host.setEnv;
          })
        cfg.extraHosts
        // {
          "*" = {
            AddKeysToAgent = "yes";
            Compression = true;
            ControlMaster = "auto";
            ControlPath = "~/.ssh/cm-%r@%h:%p";
            ControlPersist = "10m";
            TCPKeepAlive = "no";
            IPQoS = "lowdelay throughput";
            SetEnv = {TERM = "xterm";};
            IdentityFile = "~/.ssh/id_ed25519";
          };
        };
    };

    ${namespace} = {
      system.persistence.directories = [".ssh"];

      cli.shells.zsh.initContent = mkIf config.${namespace}.cli.shells.zsh.enable ''
        # Optimized keychain activation
        if [[ -f "$HOME/.keychain/$HOST-sh" ]]; then
          source "$HOME/.keychain/$HOST-sh"
        fi
        if ! ssh-add -l >/dev/null 2>&1; then
          eval "$(keychain --eval --quiet id_ed25519)"
        fi
      '';
    };
  };
}
