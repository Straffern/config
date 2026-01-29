# Overlay to use misaelaguayo's zellij fork with kitty image protocol support
# https://github.com/misaelaguayo/zellij
_final: prev: {
  zellij = prev.zellij.overrideAttrs (old: rec {
    version = "0.42.0-kitty-graphics";

    src = prev.fetchFromGitHub {
      owner = "misaelaguayo";
      repo = "zellij";
      rev = "31f64a7fa27380e467312840e7d51bb86d8e5192"; # "Implement kitty image protocol"
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will error on first build with correct hash
    };

    cargoDeps = old.cargoDeps.overrideAttrs (_: {
      inherit src;
      outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will error on first build with correct hash
    });
  });
}
