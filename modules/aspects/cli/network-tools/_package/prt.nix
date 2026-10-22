{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "prt";
  version = "0.6.0-unstable-2026-09-05";

  src = fetchFromGitHub {
    owner = "rekurt";
    repo = "prt";
    rev = "607a7d6bc53221bf58fa18bcc5e9616ef8561f9b";
    hash = "sha256-mMeC+SgHNDk4KPHevwaeWYdrVvy2uv832S+q2Ytl804=";
  };

  # Upstream has no way back from Processes; Esc/Backspace return to Connections.
  patches = [./prt-esc-back.patch];

  cargoHash = "sha256-SQo4ZM506ic5/N10/ynoWOBZ/qqk+OcSLXMU3PuOdvE=";
  cargoBuildFlags = [
    "-p"
    "prt"
  ];
  doCheck = false;

  meta = {
    description = "Terminal UI showing which processes own your network ports";
    homepage = "https://github.com/rekurt/prt";
    license = lib.licenses.mit;
    mainProgram = "prt";
  };
}
