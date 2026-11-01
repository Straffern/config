{
  den,
  inputs,
  ...
}: {
  den.aspects.tooling.dev-shell = {
    flake-parts = {pkgs, ...}: let
      system = pkgs.stdenv.hostPlatform.system;
    in {
      devShells.default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes";
        packages = [
          # Same patched nom as platform.nh; this shell shadows the system nh inside ~/.dotfiles.
          (pkgs.nh.override {nix-output-monitor = pkgs.callPackage ../platform/_package/nix-output-monitor.nix {};})
          inputs.nixos-anywhere.packages.${system}.nixos-anywhere
          inputs.deploy-rs.packages.${system}.default
          pkgs.nixd
          pkgs.statix
          pkgs.deadnix
          pkgs.alejandra
          pkgs.git
          pkgs.sops
          pkgs.ssh-to-age
          pkgs.age
        ];
      };
    };
  };

  flake-file.inputs.nixos-anywhere = {
    url = "github:numtide/nixos-anywhere";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.disko.follows = "disko";
  };
}
