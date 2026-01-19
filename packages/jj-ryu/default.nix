{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-ryu";
  version = "0.0.1-alpha.9+fix-relative-paths";

  src = fetchFromGitHub {
    owner = "Straffern";
    repo = "jj-ryu";
    rev = "cf983a5369867ec1410a9b53b1815ef4dae8c13e";
    hash = "sha256-Ny8yWxatakKwvo1mztrHi9T7yIFrYZZz4zKpZe1PitE=";
  };

  cargoHash = "sha256-1lexTIKR0QCqFeblkGxf18zCSklYMdtHbfmm2hrdK88=";

  nativeBuildInputs = [pkg-config];

  buildInputs =
    [openssl]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  # Tests require a git/jj environment which is hard to set up in the sandbox
  doCheck = false;

  meta = with lib; {
    description = "Stacked PRs for Jujutsu. Push bookmark stacks to GitHub and GitLab as chained pull requests";
    homepage = "https://github.com/dmmulroy/jj-ryu";
    license = licenses.mit;
    maintainers = [];
  };
}
