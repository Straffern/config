{
  den,
  lib,
  ...
}: let
  channelNames = [
    "journal"
    "ports"
    "ssh-hosts"
    "tailscale-exit-node"
    "gh-prs"
    "gh-issues"
    "jj-bookmark"
    "jj-diff"
    "jj-files"
    "jj-log"
    "jj-op-log"
    "jj-remotes"
    "podman-containers"
    "podman-images"
    "podman-networks"
    "podman-volumes"
  ];
in {
  den.aspects.cli.television.homeManager = {pkgs, ...}: let
    television = pkgs.television.overrideAttrs (_old: rec {
      version = "0.15.9";
      src = pkgs.fetchFromGitHub {
        owner = "alexpasmantier";
        repo = "television";
        tag = version;
        hash = "sha256-JrQUFlhAAaB+VGP184I44hSsIyfCaTMNXxyPp0E5GM0=";
      };
      cargoHash = "sha256-eD+NQYY9QnCBZ+SiOCQbcLZ2p3uX0u/nEnft2f6NfU0=";
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = cargoHash;
      };
    });
    communityChannel = name: builtins.fromTOML (builtins.readFile "${television.src}/cable/unix/${name}.toml");
  in {
    programs.television = {
      enable = true;
      package = television;
      channels = lib.genAttrs channelNames communityChannel;
    };

    # Keep the raw upstream file: 0.15.9's source.command tables do not round-trip
    # through programs.television.channels the same way the string-array channels do.
    xdg.configFile."television/cable/sesh.toml".source = "${television.src}/cable/unix/sesh.toml";
  };
}
