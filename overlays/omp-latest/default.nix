_: final: prev: let
  inherit (final) lib stdenv;

  version = "17.2.8";
  platforms = {
    aarch64-darwin = {
      asset = "omp-darwin-arm64";
      hash = "sha256-WFkeHMos4sItEfOjbDDMA9PotDU/uonEgo55hKSe5JQ=";
    };
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-Lz3QlTQaS0qB7ZMtLmUITescI/KdSBmDl+k8Ol1qizI=";
    };
    x86_64-darwin = {
      asset = "omp-darwin-x64";
      hash = "sha256-JPI3xGeQq1VNerH9enKWjgk/D+yDZuuZ9DS1aY/cV5M=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-6QPrkN6Zfl0M6VUBuEmTlsX+M3GD5Q+JC3hoT5Iy+Bo=";
    };
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform for omp: ${stdenv.hostPlatform.system}");
  src = final.fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
    inherit (platform) hash;
  };
  linuxSource = final.fetchFromGitHub {
    owner = "can1357";
    repo = "oh-my-pi";
    rev = "v${version}";
    hash = "sha256-9VRckkuGI+pYVnICJA1CurI5R9jl6L7jMulz9Y9FaJk=";
  };
  linuxNativeFilename =
    if stdenv.hostPlatform.isx86_64
    then "pi_natives.linux-x64-baseline.node"
    else "pi_natives.linux-arm64.node";
  linuxNativeAddon = final.rustPlatform.buildRustPackage {
    pname = "omp-native-wayland";
    inherit version;
    src = linuxSource;
    cargoHash = "sha256-dCg4aH0ToAs+8Gq1MBNhHY255ZetHVackU5rqMvUQQc=";
    buildType = "ci";
    cargoBuildFlags = [
      "-p"
      "pi-natives"
      "--features"
      "wayland-pipewire"
    ];
    nativeBuildInputs = [
      final.pkg-config
      final.rustPlatform.bindgenHook
    ];
    buildInputs = [
      final.libopus
      final.pipewire
    ];
    RUSTC_BOOTSTRAP = 1;
    postPatch = ''
      substituteInPlace crates/pi-natives/src/desktop/linux/wayland/capture.rs \
        --replace-fail "main_loop::MainLoop::new(None)" "main_loop::MainLoopRc::new(None)" \
        --replace-fail "context::Context::new(&mainloop)" "context::ContextRc::new(&mainloop, None)" \
        --replace-fail ".connect_fd(fd, None)" ".connect_fd_rc(fd, None)"
    '';
    doCheck = false;
    installPhase = ''
      install -Dm755 target/*/ci/libpi_natives.so "$out/${linuxNativeFilename}"
    '';
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
