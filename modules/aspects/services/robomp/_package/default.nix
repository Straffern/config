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
  source = fetchFromGitHub {
    name = "oh-my-pi-565d535-source";
    owner = "can1357";
    repo = "oh-my-pi";
    rev = "565d53515b54df32fada2564d1fe9caf1a17b738";
    hash = "sha256-Bj4ZaL8/Wdsxf1lB/k9JFC/vKERZKmm6OP3qICIZK1E=";
  };
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
    outputHash = "sha256-uCHDoNuko5Fw569x9kOr857WII3QpSyymN97QnzJyIk=";

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
      python = python3.withPackages (_: [robomp]);
    };

    meta = {
      description = "Self-hosted GitHub triage and fix bot driven by Oh My Pi";
      homepage = "https://github.com/can1357/oh-my-pi/tree/565d53515b54df32fada2564d1fe9caf1a17b738/python/robomp";
      mainProgram = "robomp";
      platforms = lib.platforms.unix;
    };
  };
in
  robomp
