{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "bv";
  version = "0.10.2";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    rev = "v${version}";
    hash = "sha256-GteCe909fpjjiFzjVKUY9dgfU7ubzue8vDOxn0NEt/A=";
  };

  vendorHash = "sha256-yhwokKjwDe99uuTlRtyoX4FeR1/RZEu7J0PMdAVrows=";

  subPackages = [ "cmd/bv" ];

  doCheck = false;

  meta = with lib; {
    description = "Terminal UI for viewing and managing Beads issues with graph-based dependency analysis";
    homepage = "https://github.com/Dicklesworthstone/beads_viewer";
    license = licenses.mit;
    mainProgram = "bv";
  };
}
