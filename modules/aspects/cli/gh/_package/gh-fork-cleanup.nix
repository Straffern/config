{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-fork-cleanup";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "CodeWithEmad";
    repo = "gh-fork-cleanup";
    rev = "v${version}";
    hash = "sha256-cuvLy33CDB257QmePGwRIC/LX4HLg6hbWnjRi4pqkNk=";
  };

  vendorHash = "sha256-JsclLNd4czZtiLapS29mK0F5Bdks69PKWKwR01Ny/jU=";

  ldflags = ["-s" "-w"];

  doCheck = false;

  postInstall = ''
    mv $out/bin/gh-delete-forks-interactively $out/bin/gh-fork-cleanup
  '';

  meta = with lib; {
    description = "GitHub CLI extension to help you clean up your fork repositories";
    homepage = "https://github.com/CodeWithEmad/gh-fork-cleanup";
    license = licenses.mit;
    mainProgram = "gh-fork-cleanup";
  };
}
