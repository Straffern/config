{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage {
  pname = "waldl";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  cargoHash = "sha256-9XsjSdNb9Nt0l3eY+cdfiVoZXjVdfGnKwbJu7sK81ws=";

  nativeBuildInputs = [pkg-config];

  buildInputs = [openssl];

  doCheck = false;

  meta = with lib; {
    description = "Wallhaven wallpaper browser TUI";
    license = licenses.mit;
    mainProgram = "waldl";
  };
}
