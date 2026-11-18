{inputs, ...}: {
  flake-file.inputs.comin = {
    url = "github:nlewo/comin";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.treefmt-nix.follows = "treefmt-nix";
  };

  # Pull-based deploys: the host polls origin, builds its own nixosConfiguration and switches.
  # `master` is switched; `testing-<hostname>` (rebased on master) is activated without a boot entry.
  den.aspects.services.comin.nixos = {pkgs, ...}: {
    imports = [inputs.comin.nixosModules.comin];
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/Straffern/config.git";
          branches.main.name = "master";
        }
      ];
      # The repository is public and a deployed commit becomes root here, so the tip commit must
      # be signed by one of Alex's GitHub signing keys.
      sshAllowedSignersPath = "${pkgs.writeText "comin-allowed-signers" ''
        alex@flensborg.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH15qRZdMTlZNShbLzFjySltD6Lr17aMGHeiQvsu1NH/
        alex@flensborg.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IwHs/v4N9J/usNHCA49toWB+GSWD+E0W3SxGbvETQ
      ''}";
    };
  };
}
