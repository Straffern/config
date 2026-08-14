{den, ...}: {
  den.aspects.profiles.common = {
    includes = [
      den.aspects.services.openssh
      den.aspects.network.networkmanager
      den.aspects.platform.locale
      den.aspects.platform.nix
      den.aspects.security.sops
      den.aspects.cli.zsh
    ];
  };
}
