{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation rec {
  pname = "cog-cli";
  version = "0.22.0";

  src = fetchurl {
    url = "https://github.com/trycog/cog-cli/releases/download/v${version}/cog-linux-x86_64.tar.gz";
    hash = "sha256-GKCO8kUUPl1OQSVhefRy3CIitdkm//nI7LKifyOx+lk=";
  };

  nativeBuildInputs = [autoPatchelfHook];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 cog $out/bin/cog
    runHook postInstall
  '';

  meta = with lib; {
    description = "Memory, code intelligence, and debugging MCP server for AI agents";
    homepage = "https://github.com/trycog/cog-cli";
    license = licenses.mit;
    mainProgram = "cog";
    platforms = ["x86_64-linux"];
  };
}
