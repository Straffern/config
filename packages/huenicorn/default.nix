{ stdenv, fetchFromGitLab, cmake, pipewire, mbedtls, makeWrapper, pkg-config
, opencv, curl, crow, nlohmann_json, glib, sysprof, wayland, wayland-protocols
, glm, ... }:

stdenv.mkDerivation {
  pname = "huenicorn";
  version = "1.0.0"; # Adjust to the desired version

  src = fetchFromGitLab {
    owner = "openjowelsofts";
    repo = "huenicorn";
    rev = "v1.0.10"; # Use a specific tag or commit hash
    sha256 =
      "0hvi45wcl2rsfdv5migldx3hcdsikwz4zxddak77qx6sj8j38lvp"; # Placeholder; update this
  };

  nativeBuildInputs = [ cmake makeWrapper pkg-config ];
  buildInputs = [
    pipewire
    mbedtls
    opencv
    curl
    crow
    nlohmann_json
    glib
    sysprof
    wayland
    wayland-protocols
    glm
  ];

  # Add this to fix the typo in the CMake script
  postPatch = ''
    substituteInPlace cmake/platforms/GnuLinux.cmake \
      --replace 'PIPEWIRER_GRABBER_AVAILABLE' 'PIPEWIRE_GRABBER_AVAILABLE'
  '';

  cmakeFlags = [
    "-DOpenCV_DIR=${opencv}/lib/cmake/opencv4"
    "-DCrow_DIR=${crow}/lib/cmake/Crow"
    "-Dnlohmann_json_DIR=${nlohmann_json}/share/cmake/nlohmann_json"
    # "-DGRABBER_TYPE=pipewire"
  ];
  # Disable the default install phase to avoid the 'make install' error
  dontInstall = true;

  postInstall = ''
    mkdir -p $out/libexec/huenicorn
    mv $out/bin/huenicorn $out/libexec/huenicorn/
    cp -r webroot $out/libexec/huenicorn/
    makeWrapper $out/libexec/huenicorn/huenicorn $out/bin/huenicorn --chdir $out/libexec/huenicorn
  '';
}
