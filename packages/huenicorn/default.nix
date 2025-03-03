{ stdenv, fetchFromGitLab, cmake, pipewire, mbedtls, makeWrapper, ... }:

stdenv.mkDerivation {
  pname = "huenicorn";
  version = "1.0.0"; # Adjust to the desired version

  src = fetchFromGitLab {
    owner = "openjowelsofts";
    repo = "huenicorn";
    rev = "v1.0.0"; # Use a specific tag or commit hash
    sha256 =
      "19d9c85f8cd91ffe0bdb2950553f5c8b052dab9b"; # Placeholder; update this
  };

  nativeBuildInputs = [ cmake makeWrapper ];
  buildInputs = [ pipewire mbedtls ];

  postInstall = ''
    mkdir -p $out/libexec/huenicorn
    mv $out/bin/huenicorn $out/libexec/huenicorn/
    cp -r webroot $out/libexec/huenicorn/
    makeWrapper $out/libexec/huenicorn/huenicorn $out/bin/huenicorn --chdir $out/libexec/huenicorn
  '';
}
