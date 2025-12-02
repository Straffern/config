{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.k3s;

in {
  options.${namespace}.services.k3s = {
    enable = mkEnableOption "k3s";
    role = mkOpt (types.nullOr types.str) "server" "server or agent";
    serverAddr = mkOpt (types.nullOr types.str) null "the addr of the server";
  };
  config = mkIf cfg.enable {

    assertions = [{
      assertion = cfg.role != "agent" || cfg.serverAddr != null;
      message = "serverAddr must be set when role is 'agent'";
    }];
    sops.secrets.k3s_token = {
      sopsFile = ../../suites/kubernetes/secrets.yaml;
    };

    services = {
      k3s = {
        enable = true;
        tokenFile =
          mkIf (cfg.role == "agent") config.sops.secrets.k3s_token.path;
        extraFlags = ''--kubelet-arg "node-ip=0.0.0.0"'';
        role = mkIf (cfg.role == "agent") "agent";
        # TODO: Make this smarter
        serverAddr = mkIf (cfg.role == "agent") cfg.serverAddr;
      };
    };

    # Persist k3s data, kubelet state, and CNI plugin state
    ${namespace}.system.impermanence.directories = [
      "/var/lib/rancher"
      "/var/lib/kubelet"
      "/var/lib/cni"
    ];
  };

}
