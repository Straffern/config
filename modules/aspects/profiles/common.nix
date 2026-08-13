{den, ...}: {
  den.aspects.profiles.common.includes = [
    den.aspects.services.openssh
    den.aspects.network.networkmanager
    den.aspects.platform.locale
    den.aspects.platform.nix
    den.aspects.platform.zsh
    den.aspects.storage.impermanence-modules
    den.aspects.security.sops
    den.aspects.styles.fonts
    den.aspects.styles.stylix
  ];
}
