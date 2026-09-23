{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "jj-starship";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-starship";
    rev = "v0.7.4";
    hash = "sha256-z2nEavoTW+aXc0lbBQe0dTGIP0qKachCUSqa+EbWxfo=";
  };

  cargoHash = "sha256-N1kjoQGPmzLwmXwSXhy6kv1e4zl7uq4tBw+U5eFwgSo=";

  # JJ-only: exclude git2 dependency
  buildFeatures = []; # Empty features (JJ-only, no git)

  # Disable tests for faster builds
  doCheck = false;

  meta = with lib; {
    description = "Unified Starship prompt module for Jujutsu (JJ) repositories - JJ only";
    homepage = "https://github.com/dmmulroy/jj-starship";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
