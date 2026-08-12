{
  den,
  inputs,
  ...
}: {
  den.aspects.security.sops.homeManager = {config, ...}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];
    sops = {
      age = {
        generateKey = true;
        keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
        sshKeyPaths = ["/home/${config.home.username}/.ssh/id_ed25519"];
      };
      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };
    home.persistence."/persist".directories = [".config/sops"];
  };
}
