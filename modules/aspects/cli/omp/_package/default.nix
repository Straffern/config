{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  makeWrapper,
  autoPatchelfHook,
  libopus,
  pipewire,
  zlib,
  pcre2,
}: let
  version = "18.0.3";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-MU6EoE4Ug5qSkctwTJjnR8af7+LsQ+fGp0qeKTsfGLk=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-O35uxoF1RR7Ari4HqsBC0YDW7gPb6hGFGqhMBQt5lfY=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-NarIrl5bhQr6GDy51cHjZ//mGHL70nALc+1f3ugXoJI=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-RzNmIGK/tDZOSrOH15QOVqcUPl3BwgcmeH5huxtS3yg=";
    };
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform for omp: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
    inherit (platform) hash;
  };
  linuxSource = fetchFromGitHub {
    owner = "can1357";
    repo = "oh-my-pi";
    rev = "v${version}";
    hash = "sha256-0ybJ+7WFtXWpVkd4p7ko3T222WX903U9brFY1oKdRHM=";
  };
  linuxNativeFilename =
    if stdenv.hostPlatform.isx86_64
    then "pi_natives.linux-x64-baseline.node"
    else "pi_natives.linux-arm64.node";
  linuxNativeAddon = rustPlatform.buildRustPackage {
    pname = "omp-native-wayland";
    inherit version;
    src = linuxSource;
    cargoHash = "sha256-+whDrozi+CIQ6KX2UIMkkG35pnQhA0dyeoA5JfNlaAA=";
    buildType = "ci";
    cargoBuildFlags = [
      "-p"
      "pi-natives"
      "--features"
      "wayland-pipewire"
    ];
    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
    ];
    buildInputs = [
      libopus
      pipewire
    ];
    RUSTC_BOOTSTRAP = 1;
    doCheck = false;
    installPhase = ''
      install -Dm755 target/*/ci/libpi_natives.so "$out/${linuxNativeFilename}"
    '';
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

      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p "$out/lib/omp/natives/${version}"
        ln -s ${linuxNativeAddon}/${linuxNativeFilename} \
          "$out/lib/omp/natives/${version}/${linuxNativeFilename}"
      ''}

      runHook postInstall
    '';

    doInstallCheck = stdenv.hostPlatform.isLinux;
    installCheckPhase = ''
      runHook preInstallCheck

      mkdir -p "$TMPDIR/.omp/natives"
      ln -s "$out/lib/omp/natives/${version}" "$TMPDIR/.omp/natives/${version}"
      HOME="$TMPDIR" "$out/bin/omp" --smoke-test | grep -q "smoke-test: ok"

      runHook postInstallCheck
    '';

    passthru.category = "AI Coding Agents";

    meta = {
      description = "Oh My Pi, an AI coding agent";
      homepage = "https://github.com/can1357/oh-my-pi";
      changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
      mainProgram = "omp";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = builtins.attrNames platforms;
    };
  }
