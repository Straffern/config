{ ... }:
final: prev:
let
  inherit (final) lib stdenv;

  version = "16.3.2";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-7hSKoYj1wJLPQG5Fd++xfolzo2IkK5jYxSB7khSbLq8=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-hft6kXDGTDetKK260guMPSsKIzxgSNyhG1Fe7T9D75E=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-HmAuc7vh4eEKnPSS6P7w0ZyTziZ0vWqcvCFPE9mam+s=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-xIQ73IwAmMrEkaQ6bTEj3/r2DmNxDRu6ePC7qHa0Nyc=";
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
