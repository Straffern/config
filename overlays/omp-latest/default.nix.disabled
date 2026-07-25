_: final: prev: let
  inherit (final) lib stdenv;

  version = "17.0.2";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-vQ+oTzby3FLgqrkfLYieU3g4kpo9Sah5ZGGjS3+dlmw=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-M/oCaA4NA+fpHyjjItSaARyTjJPzh0WMpLutC+DSge0=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-2rA4WXvfaPuqdWyP4as4egZIEKWQl7AMY8oCRR5kRew=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-ZZUsz4eI8plWICA4cVJVNFMO5RFlRwL4IH+ivSOL10M=";
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
in {
  llm-agents =
    prev.llm-agents
    // {
      omp = final.stdenvNoCC.mkDerivation {
        pname = "omp";
        inherit version src;

        dontUnpack = true;
        dontStrip = true;

        nativeBuildInputs =
          [
            final.makeWrapper
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [final.autoPatchelfHook];

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

        meta =
          prev.llm-agents.omp.meta
          // {
            changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
            sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
            platforms = builtins.attrNames platforms;
          };
      };
    };
}
