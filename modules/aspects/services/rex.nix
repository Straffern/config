# Rex (Superlogical) personal server: a systemd user service per account, reached
# from clients with `rex -S ssh://<user>@<host>`. Public beta; the flake packages
# the prebuilt unfree binary. Lingering keeps sessions alive after logout.
{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.rex = {
    url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.services.rex = {user}: {
    nixos.users.users.${user.userName}.linger = true;
    homeManager = {
      imports = [inputs.rex.homeManagerModules.default];
      services.rex.enable = true;
    };
  };
}
