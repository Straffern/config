{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  cmake,
  pkg-config,
  clang,
  llvmPackages,
  makeWrapper,
  symlinkJoin,
  autoPatchelfHook,
  # Build deps
  alsa-lib,
  openssl,
  # Vulkan (whisper.cpp GPU)
  shaderc,
  vulkan-headers,
  vulkan-loader,
  # ROCm (whisper.cpp GPU)
  rocmPackages,
  # ONNX — nixpkgs version for build-time only
  onnxruntime,
  # Runtime
  wtype,
  dotool,
  wl-clipboard,
  ydotool,
  libnotify,
  pciutils,
  # Config
  whisperGpuBackend ? "vulkan", # "vulkan", "rocm", or "none"
}:
let
  version = "0.6.4";

  # ort 2.0.0-rc.11 requires ONNX Runtime >= 1.23.x at runtime.
  # nixpkgs ships 1.22.2, so we use Microsoft's prebuilt binary for runtime.
  # Build-time uses nixpkgs onnxruntime (headers/link stubs only).
  onnxruntime-bin = stdenv.mkDerivation {
    pname = "onnxruntime-bin";
    version = "1.23.0";
    src = fetchurl {
      url = "https://github.com/microsoft/onnxruntime/releases/download/v1.23.0/onnxruntime-linux-x64-1.23.0.tgz";
      hash = "sha256-tt7qfy4iwQwEMBnylKDqTSpsCuUqAJw0hHZA23XsVYA=";
    };
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];
    installPhase = ''
      mkdir -p $out/lib $out/include
      cp -a lib/* $out/lib/
      cp -a include/* $out/include/
    '';
  };

  # ONNX engine features — always included so all engines are available at runtime
  onnxFeatures = [
    "parakeet-load-dynamic"
    "moonshine"
    "sensevoice"
    "paraformer"
    "dolphin"
    "omnilingual"
  ];

  whisperGpuFeatures = {
    vulkan = ["gpu-vulkan"];
    rocm = ["gpu-hipblas"];
    none = [];
  };

  vulkanNativeBuildInputs = [shaderc vulkan-headers vulkan-loader];
  vulkanBuildInputs = [vulkan-headers vulkan-loader];

  rocmNativeBuildInputs = [rocmPackages.clr rocmPackages.hipblas rocmPackages.rocblas];
  rocmBuildInputs = [rocmPackages.clr rocmPackages.hipblas rocmPackages.rocblas];

  runtimeDeps = [wtype dotool wl-clipboard ydotool libnotify pciutils];

  unwrapped = rustPlatform.buildRustPackage {
    pname = "voxtype";
    inherit version;

    src = fetchFromGitHub {
      owner = "peteonrails";
      repo = "voxtype";
      rev = "v${version}";
      hash = "sha256-tbgHV3lkFo/o+xWJWoJcuLmkzOdpeCCPwwhYpNbHCiU=";
    };

    cargoHash = "sha256-TWrV+l7hIdAlAbr6DzosRiD9ou/XJZEjTN2IV63QDZo=";

    nativeBuildInputs =
      [cmake pkg-config clang makeWrapper]
      ++ lib.optionals (whisperGpuBackend == "vulkan") vulkanNativeBuildInputs
      ++ lib.optionals (whisperGpuBackend == "rocm") rocmNativeBuildInputs;

    buildInputs =
      [alsa-lib openssl onnxruntime]
      ++ lib.optionals (whisperGpuBackend == "vulkan") vulkanBuildInputs
      ++ lib.optionals (whisperGpuBackend == "rocm") rocmBuildInputs;

    buildFeatures =
      onnxFeatures
      ++ (whisperGpuFeatures.${whisperGpuBackend} or []);

    # whisper-rs bindgen
    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

    # Build-time: nixpkgs onnxruntime for headers/link stubs
    ORT_LIB_LOCATION = "${onnxruntime}/lib";

    # Target AVX2-capable CPUs (Ryzen 7840U is Zen 4, supports AVX-512)
    RUSTFLAGS = "-C target-cpu=x86-64-v3";

    preBuild =
      ''
        export CMAKE_BUILD_PARALLEL_LEVEL=$NIX_BUILD_CORES
      ''
      + lib.optionalString (whisperGpuBackend == "vulkan") ''
        export VULKAN_SDK="${vulkan-loader}"
        export Vulkan_INCLUDE_DIR="${vulkan-headers}/include"
        export Vulkan_LIBRARY="${vulkan-loader}/lib/libvulkan.so"
      ''
      + lib.optionalString (whisperGpuBackend == "rocm") ''
        export HIP_PATH="${rocmPackages.clr}"
        export ROCM_PATH="${rocmPackages.clr}"
      '';

    postInstall = ''
      install -Dm644 config/default.toml \
        $out/share/voxtype/default-config.toml
    '';

    doCheck = false;

    meta = with lib; {
      description = "Push-to-talk voice-to-text for Linux";
      homepage = "https://voxtype.io";
      license = licenses.mit;
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "voxtype";
    };
  };
in
  # Wrap with runtime deps and ONNX Runtime 1.23 library path
  symlinkJoin {
    name = "voxtype-${version}";
    paths = [unwrapped];
    buildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/voxtype \
        --prefix PATH : ${lib.makeBinPath runtimeDeps} \
        --set ORT_DYLIB_PATH "${onnxruntime-bin}/lib/libonnxruntime.so" \
        --prefix LD_LIBRARY_PATH : "${onnxruntime-bin}/lib"${
        lib.optionalString (whisperGpuBackend == "vulkan")
        " \\\n      --prefix LD_LIBRARY_PATH : \"${vulkan-loader}/lib\""
      }
    '';
    inherit (unwrapped) meta;
  }
