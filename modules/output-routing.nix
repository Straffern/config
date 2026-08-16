{ den, ... }: {
  den.schema.flake-system.includes = [
    den.policies.system-to-flake-parts
  ];
  den.schema.flake-system.excludes = [
    den.policies.packages-to-flake
  ];
  den.schema.flake-parts.includes = [
    den.policies.packages-to-flake-parts
    den.aspects.outputs.public-packages
    den.aspects.tooling.dev-shell
    den.aspects.tooling.vm-smoke
    den.aspects.tooling.treefmt
    den.aspects.deployment
  ];
}
