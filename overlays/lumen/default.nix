{inputs, ...}: final: _prev: let
  lumenSrc = inputs.lumen;
in {
  lumen = final.rustPlatform.buildRustPackage {
    pname = "lumen";
    version = "2.22.0";

    src = lumenSrc;

    # Rebased upstream PR #110 fix for workspace-root path resolution.
    patches = [./jj-subdir.patch];

    # Use cargoHash instead of cargoLock for deterministic builds
    # (avoids allowBuiltinFetchGit which causes cache misses)
    cargoHash = "sha256-gQ8CMB29uce9SIqE8lmMELtz8vfrxUeyQjiI8rHdn6Y=";

    nativeBuildInputs = with final; [pkg-config perl];

    buildInputs = with final;
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
  };
}
