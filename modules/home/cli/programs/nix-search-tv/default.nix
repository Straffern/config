{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.nix-search-tv;
in {
  options.${namespace}.cli.programs.nix-search-tv = {
    enable = mkEnableOption "nix-search-tv";
  };

  config = mkIf cfg.enable {
    programs.nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
    };
  };
}
