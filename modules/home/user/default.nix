{ lib, config, pkgs, namespace, osConfig ? { }, ... }:
let
  inherit (lib) types mkIf mkDefault mkMerge;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.user;

  is-linux = pkgs.stdenv.isLinux;
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory = if cfg.name == null then
    null
  else if is-darwin then
    "/Users/${cfg.name}"
  else
    "/home/${cfg.name}";
in {
  options.${namespace}.user = {
    enable = mkOpt types.bool true "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name
      "The user account.";

    fullName =
      mkOpt types.str "Alexander Flensborg" "The full name of the user.";
    email = mkOpt types.str "alex@flensborg.me" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory
      "The user's home directory.";
    icon = mkOpt types.path ./files/pfp.jpg "My profile pic!";
    bell = mkOpt types.path ./files/fuck.oga "My bell sound!";
  };

  config = mkIf cfg.enable (mkMerge [{
    assertions = [
      {
        assertion = cfg.name != null;
        message = "${namespace}.user.name must be set";
      }
      {
        assertion = cfg.home != null;
        message = "${namespace}.user.home must be set";
      }
    ];

    home = {
      username = mkDefault cfg.name;
      homeDirectory = mkDefault cfg.home;
      # file = {
      #   pfp = mkIf (cfg.icon != null) { source = cfg.icon; };
      #   bell = mkIf (cfg.bell != null) { source = cfg.bell; };
      # };
    };

    xdg.dataFile."face.icon" = mkIf (cfg.icon != null) { source = cfg.icon; };

    xdg.dataFile."sounds/bell.oga" =
      mkIf (cfg.bell != null) { source = cfg.bell; };
  }]);
}
