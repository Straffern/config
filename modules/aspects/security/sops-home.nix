{
  den,
  inputs,
  ...
}: {
  den.aspects.security.sops = {
    vmSmoke = [
      {
        name = "sops-identity-absent";
        description = "Home Manager sops-nix stays inert without a VM identity";
        phase = "boot";
        module = {lib, ...}: {
          home-manager.sharedModules = [
            {
              systemd.user.services.sops-nix.Unit.ConditionPathExists = lib.mkForce "/run/vm-smoke-sops-identity";
            }
          ];
        };
      }
    ];

    homeManager = {
      config,
      lib,
      host,
      ...
    }: {
      imports = [inputs.sops-nix.homeManagerModules.sops];
      config = lib.mkMerge [
        {
          sops = {
            age = {
              generateKey = true;
              keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
              sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
            };
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          home.persistence."/persist".directories = [".config/sops"];
        })
      ];
    };
  };
}
