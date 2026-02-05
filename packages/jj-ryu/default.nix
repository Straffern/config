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
  version = "0.0.1-alpha.11";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-ryu";
    rev = "aade8d5acb9c2411828f38049a9b42a4b14529b8";
    hash = "sha256-gE4lvqyC2LRAWNDUGePklORWjyEofs/dHLHVBAub424=";
  };

  cargoHash = "sha256-OD1DpV4s6tgOnDEAfJWScdSKqtYArbqIJVClOtUCYa4=";

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
