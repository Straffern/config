_: final: prev: {
  # Pin zellij to 0.42.1 as a workaround for nvim rendering issues:
  # https://github.com/zellij-org/zellij/issues/4263
  zellij = prev.zellij.overrideAttrs (_old: {
    version = "0.42.1";

    src = final.fetchFromGitHub {
      owner = "zellij-org";
      repo = "zellij";
      tag = "v0.42.1";
      hash = "sha256-EK+eQfNhfVxjIsoyj43tcRjHDT9O8/n7hUz24BC42nw=";
    };

    cargoHash = "sha256-0+cU2C6zjVv2G8h7oK0ztMDdukVR6QRzN81/SfLZapY=";
  });
}
