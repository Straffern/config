{ ... }:
final: prev:
let
  inherit (final) lib stdenv;

  version = "16.3.10";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-++/rJn/G+vwQ1i4NpQp1Fo+aNKjP2fPKuXQBG83r07M=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-EJ5jr70C+ooMjLyCpO1OHAO3M/xauZSS8yRlbt96la4=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-c3ovg8X/dSvHkh07ZrpJqwnYTflw6U3hMLpMW659lQE=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-YSqe5A3WkWIdGX++VoCgCiEit5N0nEM6GrjsKYAd9Fc=";
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
