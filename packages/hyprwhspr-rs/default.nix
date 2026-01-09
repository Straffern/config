{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, openssl, alsa-lib
, wayland, libxkbcommon, libGL, whisper-cpp, vulkan-loader, onnxruntime }:

let whisper-cpp-vulkan = whisper-cpp.override { vulkanSupport = true; };
in rustPlatform.buildRustPackage rec {
  pname = "hyprwhspr-rs";
  version = "0.3.8";

  src = fetchFromGitHub {
    owner = "better-slop";
    repo = "hyprwhspr-rs";
    rev = "v${version}";
    hash = "sha256-R8EnhfEvtaq2hytU+QPMxADXvvM/vFPqS2Kstfapo+E=";
  };

  cargoHash = "sha256-cO0w1be0rwk+oFixA2ZI7WH1nNCvBtAM9L73DUDAgYo=";

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs =
    [ openssl alsa-lib wayland libxkbcommon libGL vulkan-loader onnxruntime ];

  env = {
    ORT_STRATEGY = "system";
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
  };

  postPatch = ''
    substituteInPlace src/config.rs \
      --replace-fail '/usr/bin/whisper-cli' '${whisper-cpp-vulkan}/bin/whisper-cli'
  '';

  postInstall = ''
    wrapProgram $out/bin/hyprwhspr-rs \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [ vulkan-loader libGL wayland libxkbcommon ]
      }
  '';

  doCheck = false;

  meta = with lib; {
    description =
      "Native speech-to-text voice dictation for Hyprland (Rust implementation)";
    homepage = "https://github.com/better-slop/hyprwhspr-rs";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "hyprwhspr-rs";
  };
}
