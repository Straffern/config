{inputs, ...}: final: _prev: let
  lumenSrc = inputs.lumen;
in {
  lumen = final.rustPlatform.buildRustPackage {
    pname = "lumen";
    version = "2.15.0";

    src = lumenSrc;

    # patches = [ ./jj-subdir.patch ]; # Included in Straffern/lumen fork

    # Use cargoHash instead of cargoLock for deterministic builds
    # (avoids allowBuiltinFetchGit which causes cache misses)
    cargoHash = "sha256-21SGMIssPN6bowJlevU5lCWKHu3Cwy9fU8Vt3aib1JE=";

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
      homepage = "https://github.com/Straffern/lumen";
      mainProgram = "lumen";
    };
  };
}
