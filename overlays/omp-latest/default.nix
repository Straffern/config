{ ... }:
final: prev:
let
  inherit (final) lib stdenv;

  version = "16.4.6";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-g+rEFTyLwOkwV4s5R9aG6ulA9bx4Ta5KUTlSiqPPTpI=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-rrlR+GCQT9fTw3Rpi4c8JzN5Y1lor/MtCw4AYBqikBw=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-JHWt50flnOHVkSX7u6fE2+b4F/1tniozqgqbVrgQ3vQ=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-lDfPU9nZWRhs93KVwmUGyxAcaDW1BuKAT5UfQcZ0SmE=";
    };
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform for omp: ${stdenv.hostPlatform.system}");
  src = final.fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
    inherit (platform) hash;
  };
  linuxLibs = [
    final.stdenv.cc.cc.lib
    final.zlib
    final.pcre2
  ];
in
{
  llm-agents = prev.llm-agents // {
    omp = final.stdenvNoCC.mkDerivation {
      pname = "omp";
      inherit version src;

      dontUnpack = true;
      dontStrip = true;

      nativeBuildInputs = [
        final.makeWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];

      buildInputs = lib.optionals stdenv.hostPlatform.isLinux linuxLibs;

      installPhase = ''
        runHook preInstall

        install -Dm755 "$src" "$out/lib/omp/omp"
        makeWrapper "$out/lib/omp/omp" "$out/bin/omp" \
          --set PI_SKIP_VERSION_CHECK 1 \
          ${lib.optionalString stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath linuxLibs}"}

        runHook postInstall
      '';

      passthru.category = "AI Coding Agents";

      meta = prev.llm-agents.omp.meta // {
        changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        platforms = builtins.attrNames platforms;
      };
    };
  };
}
