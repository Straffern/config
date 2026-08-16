{
  config,
  den,
  inputs,
  lib,
  ...
}: let
  enabledHosts =
    lib.concatMapAttrs (
      _system: hosts: lib.filterAttrs (_: host: host.deployment.enable) hosts
    )
    config.den.hosts;

  mkNode = name: host: let
    inherit (host) deployment;
    inherit (host) system;
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

    den.aspects.deployment.flake-parts = {system, ...}: let
      nodes =
        lib.filterAttrs (
          name: _: (enabledHosts.${name} or {}).system or null == system
        )
        deploy.nodes;
    in {
      checks = inputs.deploy-rs.lib.${system}.deployChecks {inherit nodes;};
    };

    flake-file.inputs.deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
