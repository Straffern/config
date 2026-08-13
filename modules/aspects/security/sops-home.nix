{
  den,
  inputs,
  ...
}: {
  den.aspects.security.sops.homeManager = {
    config,
    host,
    lib,
    ...
  }:
    {
      imports = [inputs.sops-nix.homeManagerModules.sops];
      sops = {
        age = {
          generateKey = true;
          keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
        };
      };
    }
    // lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [".config/sops"];
    };
}
