{ inputs, ... }:

final: prev: {
  # For example, to pull a package from unstable NixPkgs make sure you have the
  # input `unstable = "github:nixos/nixpkgs/nixos-unstable"` in your flake.

  goose-cli =
    prev.inputs.nixpkgs.packages.${prev.system}.goose-cli.overrideAttrs
    (oldAttrs: rec {
      version = "1.0.15";

      src = final.fetchFromGitHub {
        owner = "block";
        repo = "goose";
        tag = "v${version}";
        hash = "1kxc1a2c2kcpzgvbxrb1i3zjk2422rab0ckgb7n8p9cijv02kqpn";
      };
      cargoHash = "new-cargo-hash";

    });
}
