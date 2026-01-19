{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.nix-ld;
in {
  options.${namespace}.cli.programs.nix-ld = {
    enable = mkEnableOption "Nix-ld";
    libraries =
      mkOpt (types.listOf types.package) [] "A list of libraries for nix-ld";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = cfg.libraries;
    };
  };
}
