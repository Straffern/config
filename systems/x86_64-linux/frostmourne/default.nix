{ lib, namespace, pkgs, ... }:
let inherit (lib.${namespace}) enabled;
in {

  imports = [ ./hardware-configuration.nix ];

  ${namespace} = {
    system.boot.bios = enabled;
    suites.kubernetes = enabled;
  };
}
