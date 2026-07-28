_: final: prev:
let
  inherit (final) lib stdenv;

  version = "17.1.8";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-rB28gk78oCAreURSEDUTvvDAb+gDTJJI2r1dI/SCDXM=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-wteeLk1mW1S73PehdKiSsDRs4bY6StX4v+lcXsgou2Y=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-54QfvPM/3LVD3unR05I+vHY267rgo4x9Cm85xDtLQ8w=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-fuN/oqzcRh/ihvdn51OTp7rCUA/2ODuGNxQSH3PWEOQ=";
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
