{
  den,
  lib,
  ...
}: let
  channelNames = ["journal" "ports" "ssh-hosts" "tailscale-exit-node" "gh-prs" "gh-issues" "jj-bookmark" "jj-diff" "jj-files" "jj-log" "jj-op-log" "jj-remotes" "podman-containers" "podman-images" "podman-networks" "podman-volumes"];
in {
  den.aspects.cli.television.homeManager = {pkgs, ...}: let
    communityChannel = name: builtins.fromTOML (builtins.readFile "${pkgs.television.src}/cable/unix/${name}.toml");
  in {
    programs.television = {
      enable = true;
      package = pkgs.television;
      channels = lib.genAttrs channelNames communityChannel;
    };
  };
}
