{
  den,
  inputs,
  ...
}: let
  snitch = pkgs:
    (import inputs.unstable {
      localSystem = pkgs.stdenv.hostPlatform.system;
      inherit (pkgs) config;
    }).snitch;
in {
  den.aspects.cli.snitch.homeManager = {pkgs, ...}: {
    home.packages = [(snitch pkgs)];
  };
}
