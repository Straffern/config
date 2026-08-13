{
  config,
  den,
  inputs,
  lib,
  ...
}: let
  system = "x86_64-linux";
  enabledHosts = lib.filterAttrs (_: host: host.deployment.enable) config.den.hosts.${system};
  mkNode = name: host: let
    inherit (host) deployment;
  in
    {
      hostname = host.hostName;
      inherit (deployment) sshUser;
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos config.flake.nixosConfigurations.${name};
        user = "root";
      };
    }
    // lib.optionalAttrs (deployment.activationTimeout != null) {
      inherit (deployment) activationTimeout;
    }
    // lib.optionalAttrs (deployment.confirmTimeout != null) {
      inherit (deployment) confirmTimeout;
    };
  deploy.nodes = lib.mapAttrs mkNode enabledHosts;
in {
  config = {
    den.schema.host = {lib, ...}: {
      options.deployment = {
        enable = lib.mkEnableOption "deploy-rs node";
        sshUser = lib.mkOption {type = lib.types.str;};
        activationTimeout = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };
        confirmTimeout = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };
      };
    };

    flake.deploy = deploy;

    den.aspects.deployment.flake-parts = {system, ...}: {
      checks = inputs.deploy-rs.lib.${system}.deployChecks deploy;
    };

    flake-file.inputs.deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
