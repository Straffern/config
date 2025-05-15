{ pkgs, _lib, ... }:
let
  version = "0.0.49";

  src = pkgs.fetchFromGitHub {
    owner = "sst";
    repo = "opencode";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in {
  opencode = pkgs.buildGoModule {
    pname = "opencode";
    inherit version;
    inherit src;
    vendorHash = null; # Set to the correct hash after first build attempt
    go = pkgs.go_1_24;
  };
}
