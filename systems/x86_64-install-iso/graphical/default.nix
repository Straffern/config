{ lib, namespace, ... }:
let inherit (lib.${namespace}) enabled;
in {

  networking.wireless.enable = lib.mkForce false;

  ${namespace} = {
    suites.desktop = {
      enable = true;
      addons.hyprland = enabled;
    };

    user."1" = {
      name = "nixos";
      extraGroups = [ "wheel" ];
    };

  };

  system.stateVersion = "23.11";
}
