{ ... }:
final: prev:
let
  inherit (final) lib stdenv;

  version = "16.4.0";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-+Y0j4T6O9QQxOScACr4N1kVP6aME90T0DIEw7cqqds0=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-a7jXb6JevqCLLOh6eTh8HdC8v/VWTvW8efJZWocKOmg=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-Y8JTn9ACQ0g/E/4Mfbxi9sOCqBOfTel+oQW8HKE9iUs=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-x6L6MoyWUTHA0O9ioHpP5jMG7Rt6kPu7kkx1YFxo04o=";
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
