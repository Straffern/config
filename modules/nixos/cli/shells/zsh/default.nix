{
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.shells.zsh;
in {
  options.${namespace}.cli.shells.zsh = {enable = mkEnableOption "Zsh";};

  config = mkIf cfg.enable {
    programs.zsh.enable = true;

    # Ensure completions for system packages are linked
    environment.pathsToLink = ["/share/zsh"];
  };
}
