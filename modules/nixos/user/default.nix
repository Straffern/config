{ config, lib, namespace, ... }:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.user;
in {
  # TODO: Make this a attrsof submodule, to allow for creation of many users.
  options.${namespace}.user = with types; {
    name = mkOpt str "alex" "The name of the user's account";
    initialPassword = mkOpt str "1" "The initial password to use";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } "Extra options passed to users.users.<name>";
  };

  config = {
    users.mutableUsers = false;
    users.users.${cfg.name} = {
      isNormalUser = true;
      inherit (cfg) name initialPassword;
      home = "/home/${cfg.name}";
      group = "users";

      # TODO: set in modules
      extraGroups = [
        "wheel"
        "audio"
        "sound"
        "video"
        "networkmanager"
        "input"
        "tty"
        "podman"
        "kvm"
        "libvirtd"
      ] ++ cfg.extraGroups;
    } // cfg.extraOptions;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
