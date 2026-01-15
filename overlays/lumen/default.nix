{ inputs, ... }:

final: prev:
let lumenSrc = inputs.lumen;
in {
  lumen = final.rustPlatform.buildRustPackage {
    pname = "lumen";
    version = "2.15.0";

    src = lumenSrc;

    # patches = [ ./jj-subdir.patch ]; # Included in Straffern/lumen fork

    cargoLock = {
      lockFile = "${lumenSrc}/Cargo.lock";
      allowBuiltinFetchGit = true;
    };

    nativeBuildInputs = with final; [ pkg-config perl ];

    buildInputs = with final;
      [ openssl ] ++ final.lib.optionals final.stdenv.isDarwin [
        final.darwin.apple_sdk.frameworks.Security
        final.darwin.apple_sdk.frameworks.SystemConfiguration
      ];

    doCheck = false;

    meta = {
      description = "AI-powered command line tool for Git";
      homepage = "https://github.com/Straffern/lumen";
      mainProgram = "lumen";
    };
  };
}
