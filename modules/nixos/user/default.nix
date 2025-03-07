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
      name = mkOpt str "alex" "The name of the user's account";
      initialHashedPassword = mkOpt str
        "$6$Xzsm8xWpuEtAOgfe$TMvP8XkkM2UHUSCANLq0CSzmsTVWRDaZNsDn1VlOUQ9WmJUROQYbFkQqHDXmqJ5NYTZn2KY3e/LhmgPQA204z1"
        "The initial password to use";
      extraGroups =
        mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
      extraOptions = mkOpt attrs { } "Extra options passed to users.users.<n>";
    };
  })) { } "Attribute set of users indexed by numeric keys.";

  config = {
    # Ensure user.1 always exists with defaults
    ${namespace}.user = { "1" = { extraGroups = [ "wheel" ]; }; };

    users.mutableUsers = false;

    # Generate users from the attrsOf config
    users.users = lib.mapAttrs (id: user:
      lib.mkIf user.enable {
        isNormalUser = true;
        inherit (user) name initialHashedPassword;
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
      } // user.extraOptions) config.${namespace}.user;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}

