{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "cass";
  version = "0.1.36";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "coding_agent_session_search";
    rev = "v0.1.36";
    hash = "sha256-plIS1IiMsvh2Mts5JmqRwuD+OTKP/BF7LGoSNnpHw6o=";
  };

  cargoHash = "sha256-tt6RKBgCxOX33fOyPey8U8tlrgxvHOd9tc5lvlbqW84=";
  
  # Disable tests for faster builds (following jj-starship pattern)
  doCheck = false;

  meta = with lib; {
    description = "Unified TUI search over local coding agent histories";
    homepage = "https://github.com/Dicklesworthstone/coding_agent_session_search";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "cass";
  };
}