{ pkgs, lib, config, ... }:

{
  packages = [
    pkgs.openssl
    pkgs.pkg-config
  ];

  languages.rust = {
    enable = true;
    channel = "stable";
  };

  scripts = {
    dev.exec = ''
      cargo run -- "$@"
    '';
    build.exec = ''
      cargo build --release
    '';
    check.exec = ''
      cargo clippy --all-targets -- -D warnings && cargo fmt --check
    '';
    fmt.exec = ''
      cargo fmt
    '';
    test.exec = ''
      cargo test "$@"
    '';
  };

  enterShell = ''
    echo "waldl dev shell"
    echo "  dev    — debug build + run"
    echo "  build  — release build"
    echo "  check  — clippy + fmt check"
    echo "  fmt    — format code"
    echo "  test   — run tests"
  '';

  enterTest = ''
    cargo test
    cargo clippy --all-targets -- -D warnings
  '';
}
