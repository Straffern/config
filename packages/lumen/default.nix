{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl, stdenv, darwin }:

rustPlatform.buildRustPackage {
  pname = "lumen";
  version = "2.11.1";

  src = fetchFromGitHub {
    owner = "jnsahaj";
    repo = "lumen";
    rev = "v2.11.1";
    hash = "sha256-Igay4S1HmORtJasOxXwhO3oA2FRFQcAKXw9AOzWLe4M=";
  };

  cargoHash = "sha256-fACxQKGNVqOzwoMDwC71CddqEFeZ9ngH12iL8ScDNDg=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  # Disable tests by default as they might require network or specific environment
  doCheck = false;

  meta = with lib; {
    description =
      "Beautiful git diff viewer, generate commits with AI, get summary of changes, all from the CLI";
    homepage = "https://github.com/jnsahaj/lumen";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "lumen";
  };
}
