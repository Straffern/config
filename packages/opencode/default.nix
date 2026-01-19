{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "opencode";
  version = "0.0.49";

  src = fetchFromGitHub {
    owner = "sst";
    repo = "opencode";
    rev = "v${version}"; # Tag or commit reference
    hash = "sha256-LxDz6PSHU3YJImHp/trCOLtU8H4G7p+p8O2ek7OWmxE=";
  };

  vendorHash = "sha256-WsNv3Ss4zFqb1g0b5FVPEJwqlpLwabJx3CSO7a/P9ww="; # Replace with the actual hash
  # Disable tests due to config loading issues in the Nix build environment
  doCheck = false;

  meta = with lib; {
    description = "A brief description of your Go program";
    license = licenses.mit; # Adjust as needed
    maintainers = [maintainers.your-name]; # Optional
  };
}
