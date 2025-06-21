{ lib, namespace, ... }:
let inherit (lib.${namespace}) enabled;
in {
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  # networking.useNetworkd = false;

  # Disable wpa_supplicant
  networking.wireless.enable = false;
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  system = { locale.enable = true; };

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  ${namespace} = {

    services.ssh = enabled;
    suites = {
      desktop = {
        enable = true;
        addons = { gnome = enabled; };
      };
    };

    user."1" = {
      name = "nixos";
      extraGroups = [ "wheel" "networkmanager" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
    };
  };

  system.stateVersion = "23.11";
}
