{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  makeWrapper,
  autoPatchelfHook,
  zlib,
  pcre2,
}: let
  version = "18.18.0";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-Ctrio0Gh5oQLAMls4LHJ0uAlex6meC5DAuF7cXpv+wo=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-s5S/v3wOC6guAZE977X63xSm6lpx7gU0gHCrXkAYcUQ=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-7n3EyWl7Tcp8TMkhnCb3cc7D1oSPHtY1kq1UYwIb+fA=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-7CceDX30wPV6y2p6KPhYXUa9BQvO+ElPbTPbimwN+7o=";
    };
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform for omp: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
    inherit (platform) hash;
  };
  source = fetchFromGitHub {
    owner = "can1357";
    repo = "oh-my-pi";
    rev = "v${version}";
    hash = "sha256-yJao6bG6Y9BjLaY39I65dmfIqcpC4L8qwHaBXVVIjYw=";
  };
  linuxLibs = [
    stdenv.cc.cc.lib
    zlib
    pcre2
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "omp";
    inherit version src;

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs =
      [
        makeWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux linuxLibs;

    installPhase = ''
      runHook preInstall

      install -Dm755 "$src" "$out/lib/omp/omp"
      makeWrapper "$out/lib/omp/omp" "$out/bin/omp" \
        --set PI_SKIP_VERSION_CHECK 1 \
        ${lib.optionalString stdenv.hostPlatform.isLinux "--unset XDG_DATA_HOME --unset XDG_STATE_HOME --unset XDG_CACHE_HOME \\"}
        ${lib.optionalString stdenv.hostPlatform.isLinux "--set PI_NATIVE_VARIANT baseline \\"}
        ${lib.optionalString stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath linuxLibs}"}

      runHook postInstall
    '';

    doInstallCheck = stdenv.hostPlatform.isLinux;
    installCheckPhase = ''
      runHook preInstallCheck

      HOME="$TMPDIR" "$out/bin/omp" --smoke-test | grep -q "smoke-test: ok"

      runHook postInstallCheck
    '';

    passthru = {
      category = "AI Coding Agents";
      inherit source;
    };

    meta = {
      description = "Oh My Pi, an AI coding agent";
      homepage = "https://github.com/can1357/oh-my-pi";
      changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
      mainProgram = "omp";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = builtins.attrNames platforms;
    };
  }
