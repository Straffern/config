{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

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

    nixos = {
      imports = [inputs.sops-nix.nixosModules.sops];
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };

    homeManager = {
      config,
      lib,
      host,
      pkgs,
      ...
    }: {
      imports = [inputs.sops-nix.homeManagerModules.sops];
      config = lib.mkMerge [
        {
          home.packages = [pkgs.sops];
          home.sessionVariables.SOPS_AGE_KEY_CMD = lib.getExe (pkgs.writeShellApplication {
            name = "sops-ssh-age-key";
            runtimeInputs = [pkgs.ssh-to-age];
            text = ''
              key="$HOME/.ssh/id_ed25519"
              [[ -f "$key" && -f "$key.pub" ]] || exit 0
              recipient=$(ssh-to-age -i "$key.pub")
              [[ "''${SOPS_AGE_RECIPIENT:-}" == "$recipient" ]] || exit 0

              # ssh-to-age errors can contain the private key.
              if ssh-to-age -private-key -i "$key" 2>/dev/null; then
                exit 0
              fi

              IFS= read -r -s -p "SOPS SSH key passphrase: " SSH_TO_AGE_PASSPHRASE </dev/tty 2>/dev/tty
              printf '\n' >/dev/tty
              export SSH_TO_AGE_PASSPHRASE
              ssh-to-age -private-key -i "$key" 2>/dev/null
            '';
          });

          sops.age = {
            generateKey = true;
            keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
            sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          home.persistence."/persist".directories = [".config/sops"];
        })
      ];
    };
  };
}
