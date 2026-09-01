{
  fetchurl,
  helium,
  lib,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "chrome-devtools-helium";
  version = "1.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.8.0.tgz";
    hash = "sha256-rAM0QQzqddEaXrtVX7sBOaSjlN412YzCo7wKlZ8ATN0=";
  };

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/chrome-devtools-mcp $out/bin
    cp -r build package.json $out/lib/chrome-devtools-mcp/
    substituteInPlace $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools.js \
      --replace-fail \
        "const DEFAULT_CLI_ARGS = ['--viaCli'];" \
        "const DEFAULT_CLI_ARGS = ['--viaCli', '--executablePath', '${helium}/bin/helium'];"
    makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools \
      --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools.js
    makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools-mcp \
      --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js

    runHook postInstall
  '';

  meta = {
    description = "Chrome DevTools CLI configured to launch Helium";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools";
  };
}
