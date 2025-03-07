{ config, lib, namespace, ... }:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt;
  # Removed cfg since we now access config.${namespace}.user directly
in {
  # Implemented attrsof submodule to allow for creation of many users.
  options.${namespace}.user = mkOpt (types.attrsOf (types.submodule {
    options = with types; {
      enable = mkOpt bool true "Whether this user is enabled.";
      name = mkOpt str "nixos" "The name of the user's account";
      initialHashedPassword = mkOpt (types.nullOr str) null
        "The initial password to use (null for no password)";
      extraGroups =
        mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
      authorizedKeys = mkOpt (listOf str) [ ] "SSH public keys to allow access";
      extraOptions = mkOpt attrs { } "Extra options passed to users.users.<n>";
    };
  })) { } "Attribute set of users indexed by numeric keys.";

  config = {
    # Ensure user.1 always exists with defaults
    ${namespace}.user = { "1" = { extraGroups = [ "wheel" ]; }; };

    users.mutableUsers = false;

    # Generate users from the attrsOf config
    users.users = lib.mapAttrs (id: user:
      lib.mkIf user.enable (lib.mkMerge [
        {
          isNormalUser = true;
          inherit (user) name;
          home = "/home/${user.name}";
          group = "users";

          # Merge default groups with user's extraGroups
          extraGroups = [
            "audio"
            "sound"
            "video"
            "networkmanager"
            "input"
            "tty"
            "podman"
            "kvm"
            "libvirtd"
          ] ++ user.extraGroups;

          # Configure openssh authorized keys if provided
          openssh.authorizedKeys.keys = user.authorizedKeys;
        }
        (lib.mkIf (user.initialHashedPassword != null) {
          inherit (user) initialHashedPassword;
        })
      ]) // user.extraOptions) config.${namespace}.user;

    home-manager = {
      useGlobalPkgs =
        true; # NOTE: When this is enabled, don't set nixpkgs options in home-manager configs
      useUserPackages = true;
    };

    # Set allowOther for home persistence for each user
    # home.persistence = lib.mapAttrs' (id: user: 
    #   lib.nameValuePair "/persist/home/${user.name}" { 
    #     allowOther = true; 
    #   }
    # ) (lib.filterAttrs (id: user: user.enable) config.${namespace}.user);
  };
}

