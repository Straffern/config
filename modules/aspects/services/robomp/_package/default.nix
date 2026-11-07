{
  lib,
  fetchFromGitHub,
  python3,
  callPackage,
  makeWrapper,
  git,
  stdenvNoCC,
  cacert,
  bun,
}: let
  version = "0.1.0";
  source = omp.passthru.source;
  omp = callPackage ../../../cli/omp/_package {};
  ompRpc = callPackage ./omp-rpc.nix {inherit source python3;};
  webDeps = stdenvNoCC.mkDerivation {
    pname = "robomp-web-bun-cache";
    inherit version;

    dontUnpack = true;
    nativeBuildInputs = [bun];

    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-R7YCW9qxz6r6wa7e3ULps+ATKMtNbVMjBeGVI0e0UTk=";

    buildPhase = ''
      export HOME="$TMPDIR/home"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/cache"
      mkdir -p \
        "$HOME" \
        "$BUN_INSTALL_CACHE_DIR" \
        "$TMPDIR/work/python/robomp/web"

      cp "${source}/package.json" "${source}/bun.lock" "$TMPDIR/work/"
      cp -R "${source}/patches" "$TMPDIR/work/patches"
      cp "${source}/python/robomp/web/package.json" \
        "$TMPDIR/work/python/robomp/web/"

      cd "$TMPDIR/work"
      bun install \
        --filter robomp-web \
        --ignore-scripts \
        --linker=hoisted

      mkdir -p "$out"
      cp -RL "$BUN_INSTALL_CACHE_DIR/." "$out/"
      chmod -R u+w "$out"
    '';

    dontInstall = true;
  };
  robomp = python3.pkgs.buildPythonApplication {
    pname = "robomp";
    inherit version;
    pyproject = true;

    src = source;
    sourceRoot = "${source.name}/python/robomp";

    # The proxy holds the write credential; let it push only robomp's own workspace branches.
    patches = [./proxy-push-farm-branches-only.patch];

    build-system = [python3.pkgs.setuptools];

    dependencies = with python3.pkgs;
      [
        fastapi
        uvicorn
        httpx
        pydantic
        pydantic-settings
        python-dotenv
        click
        ompRpc
      ]
      ++ uvicorn.optional-dependencies.standard;

    nativeBuildInputs = [
      makeWrapper
      bun
    ];

    postPatch = ''
      packageRoot="$PWD"
      webRoot="$TMPDIR/robomp-web"
      webCache="$TMPDIR/bun-cache"

      mkdir -p "$webRoot/python/robomp"
      cp "${source}/package.json" "${source}/bun.lock" "$webRoot/"
      cp -R "${source}/patches" "$webRoot/patches"
      cp -R "${source}/python/robomp/web" "$webRoot/python/robomp/web"
      cp -R "${webDeps}/." "$webCache"
      chmod -R u+w "$webRoot" "$webCache"

      export HOME="$TMPDIR/home"
      export BUN_INSTALL_CACHE_DIR="$webCache"
      mkdir -p "$HOME"

      cd "$webRoot"
      bun install \
        --offline \
        --filter robomp-web \
        --ignore-scripts \
        --linker=hoisted
      (
        cd python/robomp/web
        bun ../../../node_modules/vite/bin/vite.js build
      )

      rm -rf "$packageRoot/src/static"
      cp -R "$webRoot/python/robomp/web/dist" "$packageRoot/src/static"
      cd "$packageRoot"
    '';

    postFixup = ''
      wrapProgram "$out/bin/robomp" \
        --prefix PATH : ${
        lib.makeBinPath [
          omp
          git
          bun
        ]
      }
    '';

    pythonImportsCheck = [
      "robomp"
      "robomp.proxy"
    ];

    passthru = {
      inherit source ompRpc;
      piRoot = source;
      # withPackages drops applications; toPythonModule puts robomp.proxy on the env's path.
      python = python3.withPackages (_: [(python3.pkgs.toPythonModule robomp)]);
    };

    meta = {
      description = "Self-hosted GitHub triage and fix bot driven by Oh My Pi";
      homepage = "https://github.com/can1357/oh-my-pi/tree/v${omp.version}/python/robomp";
      mainProgram = "robomp";
      platforms = lib.platforms.unix;
    };
  };
in
  robomp
