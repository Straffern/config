{
  lib,
  rustPlatform,
  pkg-config,
  perl,
  openssl,
  stdenv,
  darwin,
  src,
}:
rustPlatform.buildRustPackage {
  pname = "lumen";
  version = "2.32.0";

  inherit src;

  # Rebased upstream PR #110 fix for workspace-root path resolution.
  patches = [../_patches/jj-subdir.patch];

  cargoHash = "sha256-ZXw7KEvf1sUHWIM5R4Th2SmekTX6rGXznAq3mtcf3Zo=";

  nativeBuildInputs = [pkg-config perl];

  buildInputs =
    [openssl]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  doCheck = false;

  meta = {
    description = "AI-powered command line tool for Git";
    homepage = "https://github.com/jnsahaj/lumen";
    mainProgram = "lumen";
  };
}
