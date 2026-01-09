{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl, onnxruntime, lld }:

rustPlatform.buildRustPackage {
  pname = "cass";
  version = "0.1.55";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "coding_agent_session_search";
    rev = "v0.1.55";
    hash = "sha256-T7UjwSetD8PgmSOUII9+gE0JQBJnH6PC2ay+2LoXzNQ=";
  };

  cargoHash = "sha256-d+KR0IA1Yca0XPorf8B4QWmesmChCJ55aQny7JDc6XM=";

  nativeBuildInputs = [ pkg-config lld ];
  buildInputs = [ openssl onnxruntime ];

  env = {
    ORT_STRATEGY = "system";
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
  };

  # Disable tests for faster builds (following jj-starship pattern)
  doCheck = false;

  meta = with lib; {
    description = "Unified TUI search over local coding agent histories";
    homepage =
      "https://github.com/Dicklesworthstone/coding_agent_session_search";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "cass";
  };
}
