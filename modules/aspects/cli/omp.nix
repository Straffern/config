{den, ...}: let
  omp = pkgs: let
    inherit (pkgs) lib stdenv;
    version = "17.3.7";
    platforms = {
      aarch64-darwin = {
        asset = "omp-darwin-arm64";
        hash = "sha256-15pzXN7TNorW536Yj33DA6/rAzGi3W/0Zm5pRRLeLgk=";
      };
      aarch64-linux = {
        asset = "omp-linux-arm64";
        hash = "sha256-jHNhiSj4RBEY61eD5LBIApT5dB1/6dWbzyfri0rGG+w=";
      };
      x86_64-darwin = {
        asset = "omp-darwin-x64";
        hash = "sha256-vZTWV9ifgYuJ/G9Iyh0NPNNElCocJohv7m4Qfmh6meI=";
      };
      x86_64-linux = {
        asset = "omp-linux-x64";
        hash = "sha256-TubtKDvhAhHUc+ndRbEn8iKYIN8+JyKlowW5p/l364M=";
      };
    };
    platform =
      platforms.${stdenv.hostPlatform.system}
          or (throw "Unsupported platform for omp: ${stdenv.hostPlatform.system}");
    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
      inherit (platform) hash;
    };
    linuxSource = pkgs.fetchFromGitHub {
      owner = "can1357";
      repo = "oh-my-pi";
      rev = "v${version}";
      hash = "sha256-PqPEUz6uAYyxLupt0QZbX9rvY1UpyGPObeQHgx3SAjU=";
    };
    linuxNativeFilename =
      if stdenv.hostPlatform.isx86_64
      then "pi_natives.linux-x64-baseline.node"
      else "pi_natives.linux-arm64.node";
    linuxNativeAddon = pkgs.rustPlatform.buildRustPackage {
      pname = "omp-native-wayland";
      inherit version;
      src = linuxSource;
      cargoHash = "sha256-zHKQg0qZUAn4NayDZZ/RWo6xrURnDk0yg5XqcN9Dc/8=";
      buildType = "ci";
      cargoBuildFlags = [
        "-p"
        "pi-natives"
        "--features"
        "wayland-pipewire"
      ];
      nativeBuildInputs = [
        pkgs.pkg-config
        pkgs.rustPlatform.bindgenHook
      ];
      buildInputs = [
        pkgs.libopus
        pkgs.pipewire
      ];
      RUSTC_BOOTSTRAP = 1;
      doCheck = false;
      installPhase = ''
        install -Dm755 target/*/ci/libpi_natives.so "$out/${linuxNativeFilename}"
      '';
    };
    linuxLibs = [
      stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.pcre2
    ];
  in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "omp";
      inherit version src;

      dontUnpack = true;
      dontStrip = true;

      nativeBuildInputs =
        [
          pkgs.makeWrapper
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [pkgs.autoPatchelfHook];

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
    };
in {
  den.aspects.cli.omp.homeManager = {pkgs, ...}: let
    ompPackage = omp pkgs;
  in {
    home.packages = [ompPackage];
    home.file.".omp/natives/${ompPackage.version}".source = "${ompPackage}/lib/omp/natives/${ompPackage.version}";
  };
}
