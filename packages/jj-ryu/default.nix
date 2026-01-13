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
  version = "0.0.1-alpha.9";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-ryu";
    rev = "f4266e2e67cd34e50c552709f87e1506ad27e278";
    hash = "sha256-jafGP3gseSTHI20TqWsbTKLxqNKIpamopwA+0hQtnSs=";
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
