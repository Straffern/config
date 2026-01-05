{ lib, python3Packages, fetchFromGitHub, cmake, ninja, ffmpeg, which
, vulkan-loader, vulkan-headers, shaderc, rocmPackages, autoPatchelfHook
, gpuSupport ? "vulkan" # "vulkan", "rocm", or "none"
}:

python3Packages.buildPythonPackage rec {
  pname = "pywhispercpp";
  version = "1.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "abdeladim-s";
    repo = "pywhispercpp";
    rev = "v${version}";
    hash = "sha256-Xo8CQqOeDrQQTgYcV5EkSKCZkbkI1WVeW7OqL0CEQ9Q=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python3Packages.setuptools
    python3Packages.cython
    which
    cmake
    ninja
    python3Packages.scikit-build
    autoPatchelfHook
  ] ++ lib.optionals (gpuSupport == "vulkan") [ shaderc ];

  dontUseCmakeConfigure = true;

  build-system = with python3Packages; [ setuptools cython setuptools-scm ];

  buildInputs = [ python3Packages.pybind11 ffmpeg ]
    ++ lib.optionals (gpuSupport == "vulkan") [
      vulkan-loader
      vulkan-headers
      shaderc
    ] ++ lib.optionals (gpuSupport == "rocm") [
      rocmPackages.clr
      rocmPackages.rocblas
      rocmPackages.hipblas
    ];

  # Vulkan loader needed at runtime for GPU acceleration
  propagatedBuildInputs = with python3Packages;
    [ numpy requests tqdm platformdirs ]
    ++ lib.optionals (gpuSupport == "vulkan") [ vulkan-loader ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"repairwheel",' "" \
      --replace-fail '"ninja",' "" \
      --replace-fail '"cmake>=3.12",' ""
  '';

  # pywhispercpp setup.py converts ALL env vars to -D CMake flags (line 153-154)
  # Use GGML_VULKAN=1 (not WHISPER_VULKAN which is deprecated)
  preBuild = ''
    export NO_REPAIR=1
  '' + lib.optionalString (gpuSupport == "vulkan") ''
    export GGML_VULKAN=1
  '' + lib.optionalString (gpuSupport == "rocm") ''
    export GGML_HIPBLAS=1
  '';

  postInstall = ''
    find $out -type f -name "*.so*" -exec patchelf --set-rpath '$ORIGIN' {} \;
  '';

  pythonImportsCheck = [ "pywhispercpp" ];

  meta = with lib; {
    description = "Python bindings for whisper.cpp";
    homepage = "https://github.com/abdeladim-s/pywhispercpp";
    license = licenses.mit;
    maintainers = [ ];
  };
}

