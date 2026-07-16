_: final: prev: let
  inherit (final) lib stdenv;

  version = "16.5.0";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-CMmy5s/rS/E3jb9aQLIR1f2lbnMfsBrOBt9amapqRHw=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-ho95rmIiIGBxE4RUsa2V4fKEoET7YCcawJGmRGTrJsc=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-LAbMY2gBkVjm6LsRUcrJae5emhNyXSdVteQjXsDnSPw=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-B4gqZJ7+CqAp/xDUenF6qrGAOSyq2ZKttUS6aHrAaoA=";
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
