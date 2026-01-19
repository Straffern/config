{
  lib,
  config,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.nix-index;
in {
  options.${namespace}.cli.programs.nix-index = {
    enable = mkEnableOption "Nix index";
  };

  imports = with inputs; [nix-index-database.homeModules.nix-index];

  config = mkIf cfg.enable {
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    programs.nix-index-database.comma.enable = true;
  };
}
