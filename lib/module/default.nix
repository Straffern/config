{lib, ...}:
with lib; rec {
  mkOpt = type: default: description:
    mkOption {inherit type default description;};

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  ## Create a package NixOS module option.
  ##
  ## ```nix
  ## lib.mkPackageOpt pkgs.rofi-wayland "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkPackageOpt = mkOpt types.package;

  ## Create a package NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkPackageOpt' pkgs.rofi-wayland
  ## ```
  ##
  #@ Type -> Any -> String
  mkPackageOpt' = mkOpt types.package;

  enabled = {enable = true;};

  disabled = {enable = false;};
}
