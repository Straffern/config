{
  config,
  den,
  inputs,
  lib,
  ...
}: let
  system = "x86_64-linux";
  enabledHosts = lib.filterAttrs (_: host: host.enable) config.denful.deployment.nodes;
  mkNode = name: host:
    {
      inherit (host) hostname sshUser;
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos config.flake.nixosConfigurations.${name};
        user = "root";
      };
    }
    // lib.optionalAttrs (host.activationTimeout != null) {
      inherit (host) activationTimeout;
    }
    // lib.optionalAttrs (host.confirmTimeout != null) {
      inherit (host) confirmTimeout;
    };
  deploy.nodes = lib.mapAttrs mkNode enabledHosts;
in {
  options.denful.deployment.nodes = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "deploy-rs node";
          hostname = lib.mkOption {type = lib.types.str;};
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
      }
    );
    default = {};
  };
  config = {
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
