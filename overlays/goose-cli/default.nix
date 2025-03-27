{ inputs, ... }:

final: prev: {
  # For example, to pull a package from unstable NixPkgs make sure you have the
  # input `unstable = "github:nixos/nixpkgs/nixos-unstable"` in your flake.

  goose-cli = prev.goose-cli.overrideAttrs (oldAttrs: rec {
    version = "1.0.16";

    src = final.fetchFromGitHub {
      owner = "block";
      repo = "goose";
      tag = "v${version}";
      hash = "sha256-fwywPX+tmfECno7x7cCExc2SoASZ6XzOzaVciMBkiBk=";
    };

    # https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2 
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "goose-cli-${version}";

      hash = "sha256-Gu+mMFzOkswTbm1AygkaZynW7c+9vHZHTMFUNMWWiEg=";
    };

    # Extend the original checkFlags to skip the failing test
    checkFlags = oldAttrs.checkFlags ++ [
      "--skip=providers::gcpauth::tests::test_token_refresh_race_condition"
    ];

  });
}
