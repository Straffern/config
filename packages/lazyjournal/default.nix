{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "lazyjournal";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "Lifailon";
    repo = "lazyjournal";
    rev = version;
    hash = "sha256-fWFj76qaqhTgkI9EepRo88H0HMzzfmCIXgJABAbW9RU=";
  };

  vendorHash = "sha256-Wl8DmEBt1YtTk9QEvWybSWRQm0Lnfd5q3C/wg+gP33g=";

  ldflags = [ "-s" "-w" ];

  doCheck = false;

  meta = with lib; {
    description =
      "TUI for journalctl, file system logs, Docker and Podman containers";
    homepage = "https://github.com/Lifailon/lazyjournal";
    license = licenses.mit;
    mainProgram = "lazyjournal";
  };
}
