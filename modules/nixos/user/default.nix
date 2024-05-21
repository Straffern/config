{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.user;
  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = {fileName = defaultIconFileName;};
  };
  propagatedIcon =
    pkgs.runCommandNoCC "propagated-icon"
    {passthru = {inherit (cfg.icon) fileName;};}
    ''
      local target="$out/share/icons/user/${cfg.name}"
      mkdir -p "$target"

      cp ${cfg.icon} "$target/${cfg.icon.fileName}"
    '';
in {
  options.user = with types; {
    name = mkOpt str "alexander" "The name to use for the user account.";
    fullName = mkOpt str "Alexander Flensborg" "The full name of the user.";
    email = mkOpt str "alexanderflensborg@hotmail.dk" "The email of the user.";
    initialHashedPassword =
      mkOpt str "$6$Sjfq/GwmUzoQkfye$z5XLD2Flo4hbELz/LESNS/5rbzN96zfmtU8OZgdUhwwLYXMIsODn0M./yFBXdr.gMo8jb0wRjPCC4b82RbE2d/"
      "The initial password to use when the user is first created.";
    icon =
      mkOpt (nullOr package) defaultIcon
      "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [] "Groups for the user to be assigned.";
    extraOptions =
      mkOpt attrs {}
      "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      propagatedIcon
    ];

    environment.sessionVariables.FLAKE = "/home/${cfg.name}/.dotfiles";

    home = {
      file = {
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "dev/.keep".text = "";
        ".face".source = cfg.icon;
        "Pictures/${
          cfg.icon.fileName or (builtins.baseNameOf cfg.icon)
        }".source =
          cfg.icon;
      };
     persist.directories = [
        "Documents"
        "Music"
        "Pictures"
        "dev"

        ".dotfiles"
      ];
    };


    users.users.${cfg.name} =
      {
        isNormalUser = true;
        inherit (cfg) name initialHashedPassword;
        # home = "/home/${cfg.name}";

        ignoreShellProgramCheck = true;

        # Arbitrary user ID to use for the user. Since I only
        # have a single user on my machines this won't ever collide.
        # However, if you add multiple users you'll need to change this
        # so each user has their own unique uid (or leave it out for the
        # system to select).
        uid = 1000;

        extraGroups =
          ["wheel" "audio" "sound" "video" "networkmanager" "input" "tty" "docker"]
          ++ cfg.extraGroups;
      }
      // cfg.extraOptions;
  };
}
