{ config, lib, namespace, ... }:
let
  inherit (lib) types mkIf mkMerge;
  inherit (lib.${namespace}) mkOpt;

  # Helper function to define common user defaults
  defaultGroups = [
    "audio"
    "sound"
    "video"
    "networkmanager"
    "input"
    "tty"
    "podman"
    "kvm"
    "libvirtd"
  ];

  # Define user submodule
  userSubmodule = types.submodule {
    options = {
      enable = mkOpt types.bool true "Whether this user is enabled.";
      name = mkOpt types.str "nixos" "The name of the user's account";
      initialHashedPassword = mkOpt (types.nullOr types.str) null
        "The initial password to use (null for no password)";
      extraGroups =
        mkOpt (types.listOf types.str) [ ] "Additional groups for the user.";
      authorizedKeys =
        mkOpt (types.listOf types.str) [ ] "SSH public keys to allow access";
      extraOptions =
        mkOpt types.attrs { } "Extra options passed to users.users.<name>";
      shell = mkOpt (types.nullOr types.package) null
        "The user's shell (null for system default)";
    };
  };

in {
  options.${namespace}.user = mkOpt (types.attrsOf userSubmodule) { }
    "Attribute set of users indexed by numeric keys, with 'name' defining the username.";

  config = {
    # Default user configuration
    ${namespace}.user = { "1" = { extraGroups = [ "wheel" ]; }; };

    users = {
      mutableUsers = false;

      # Generate users configuration
      users = lib.mapAttrs' (id: user:
        lib.nameValuePair user.name (mkIf user.enable (mkMerge [
          {
            isNormalUser = true;
            home = "/home/${user.name}";
            group = "users";
            extraGroups = defaultGroups ++ user.extraGroups;
            openssh.authorizedKeys.keys = user.authorizedKeys;
          }
          (mkIf (user.initialHashedPassword != null) {
            initialHashedPassword = user.initialHashedPassword;
          })
          (mkIf (user.shell != null) { shell = user.shell; })
          user.extraOptions
        ]))) config.${namespace}.user;
    };

    # Home Manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };

    # Assertions
    assertions = [{
      assertion = lib.all (user:
        user.initialHashedPassword != "" || user.initialHashedPassword == null)
        (lib.attrValues config.${namespace}.user);
      message = "Empty string is not a valid initialHashedPassword";
    }];

  };
}
