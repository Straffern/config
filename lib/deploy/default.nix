{ lib, inputs, namespace, }:
let inherit (inputs) deploy-rs;
in rec {
  ## Create deployment configuration for use with deploy-rs.
  ##
  ## ```nix
  ## mkDeploy {
  ##   inherit self;
  ##   overrides = {
  ##     my-host.system.sudo = "doas -u";
  ##   };
  ## }
  ## ```
  ##
  #@ { self: Flake, overrides: Attrs ? {} } -> Attrs
  mkDeploy = { self, overrides ? { }, }:
    let
      hosts = self.nixosConfigurations or { };
      names = builtins.attrNames hosts;
      nodes = lib.genAttrs names (name:
        let
          host = hosts.${name};
          user = host.config.${namespace}.user."1".name or null;
          system = host.pkgs.stdenv.hostPlatform.system;
        in (overrides.${name} or { }) // {
          hostname = overrides.${name}.hostname or "${name}";
          profiles = (overrides.${name}.profiles or { }) // {
            system = (overrides.${name}.profiles.system or { }) // {
              path = deploy-rs.lib.${system}.activate.nixos host;
            } // lib.optionalAttrs (user != null) {
              user = "root";
              sshUser = user;
            } // lib.optionalAttrs
              (host.config.${namespace}.security.doas.enable or false) {
                sudo = "doas -u";
              };
          };
        });
    in { inherit nodes; };
}
