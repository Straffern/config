{den, ...}: {
  den.aspects.profiles.common.includes = [
    den.aspects.apps.brave
    den.aspects.apps.helium
    den.aspects.cli.sourcegraph
    den.aspects.cli.shell-utils
    den.aspects.cli.unzip
    den.aspects.cli.zsh
    den.aspects.platform.zsh
    den.aspects.services.openssh
    den.aspects.network.networkmanager
    den.aspects.platform.locale
    den.aspects.platform.nix
    den.aspects.storage.impermanence-modules
    den.aspects.security.sops
    den.aspects.styles.fonts
    den.aspects.styles.stylix
  ];
}
