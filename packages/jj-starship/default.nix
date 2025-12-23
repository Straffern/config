{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "jj-starship";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-starship";
    rev = "v0.2.1";
    hash = "sha256-wmQn1qw+jfxH9xBS7bdgWiK369bCeGV9klZzlFHrGOw=";
  };

  cargoHash = "sha256-dGutKgOG0gPDYcTODrBUmmJBl2k437E5/lz+9cFzgs4=";
  
  # JJ-only: exclude git2 dependency
  buildFeatures = [ ]; # Empty features (JJ-only, no git)
  
  # Disable tests for faster builds
  doCheck = false;

  meta = with lib; {
    description = "Unified Starship prompt module for Jujutsu (JJ) repositories - JJ only";
    homepage = "https://github.com/dmmulroy/jj-starship";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}