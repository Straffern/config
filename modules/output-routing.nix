{
  den,
  ...
}: {
  den.schema.flake-system.includes = [
    den.policies.system-to-flake-parts
  ];
  den.schema.flake-system.excludes = [
    den.policies.packages-to-flake
  ];
  den.schema.flake-parts.includes = [
    den.policies.packages-to-flake-parts
    den.aspects.apps.clipy
    den.aspects.apps.waldl
    den.aspects.services.hermes
    den.aspects.cli.btop
    den.aspects.cli.gh
    den.aspects.cli.jj
    den.aspects.cli.kitty
    den.aspects.cli.lazyjournal
    den.aspects.cli.neovim
    den.aspects.hardware.amd-debug-tools
    den.aspects.hardware.v4l2loopback
    den.aspects.styles.packages
    den.aspects.tooling.dev-shell
    den.aspects.tooling.treefmt
    den.aspects.deployment
  ];
}
