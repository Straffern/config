_: final: prev: let
  version = "0.20.2";
  zjstatusWasm = final.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v${version}/zjstatus.wasm";
    hash = "sha256-OSg7Q1AWKW32Y9sHWJbWOXWF1YI5mt0N4Vsa2fcvuNg=";
  };
  zjframesWasm = final.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v${version}/zjframes.wasm";
    hash = "sha256-MOnD+6Y90RCpLpPl0VLMUiyVJ7ypZOvMcYjDOUEOGXo=";
  };
in {
  zjstatus = final.stdenvNoCC.mkDerivation {
    pname = "zjstatus";
    inherit version;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -Dm644 ${zjstatusWasm} $out/bin/zjstatus.wasm
      install -Dm644 ${zjframesWasm} $out/bin/zjframes.wasm

      runHook postInstall
    '';

    meta = {
      description = "Configurable status bar plugin for Zellij";
      homepage = "https://github.com/dj95/zjstatus";
      changelog = "https://github.com/dj95/zjstatus/releases/tag/v${version}";
      license = final.lib.licenses.mit;
    };
  };
}
