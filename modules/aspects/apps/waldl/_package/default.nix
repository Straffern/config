{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage {
  pname = "waldl";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.lock
      ./Cargo.toml
      ./src
    ];
  };

  cargoHash = "sha256-CFkAratnw6551Dr2INtuRnOaZcOd/ZasHdJ7rCZC7PM=";

  nativeBuildInputs = [pkg-config];

  buildInputs = [openssl];

  doCheck = false;

  meta = with lib; {
    description = "Wallhaven wallpaper browser TUI";
    license = licenses.mit;
    mainProgram = "waldl";
  };
}
