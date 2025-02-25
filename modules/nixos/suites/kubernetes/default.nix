{ lib, config, namespace, ... }:
with lib;
with lib.nixicle;
let
  inherit (lib) mkEnableOption types mkIf;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.suites.kubernetes;
in {
  options.${namespace}.suites.kubernetes = {
    enable = mkEnableOption "Enable kubernetes configuration";
    role = mkOpt (types.nullOr types.str) "server"
      "Whether this node is a server or agent";
    serverAddr = mkOpt (types.nullOr types.str) null
      "Address of the server node (required when role is 'agent')";
  };

  config = mkIf cfg.enable {
    # Validate that serverAddr is set when role is agent
    assertions = [{
      assertion = cfg.role != "agent" || cfg.serverAddr != null;
      message = "serverAddr must be set when role is 'agent'";
    }];

    roles = { server.enable = true; };

    ${namespace} = {
      services.k3s = {
        enable = true;
        role = cfg.role;
        serverAddr = cfg.serverAddr;
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ 53 8472 ];

      allowedTCPPorts = [ 22 53 6443 6444 9000 445 139 ];
    };
  };
}
