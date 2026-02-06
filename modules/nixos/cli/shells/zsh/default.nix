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
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      # Let Home Manager own compinit — prevents /etc/zshrc from running
      # compinit before ~/.zshrc, which writes a stale zcompdump missing
      # custom completions from HM's fpath.
      enableGlobalCompInit = false;
      # Root fallback: compinit for non-HM users (root, service accounts)
      interactiveShellInit = ''
        if [[ $EUID -eq 0 && -z ''${__HM_ZSH_SESS_VARS_SOURCED+x} ]]; then
          autoload -U compinit && compinit
        fi
      '';
    };

    # Ensure completions for system packages are linked
    environment.pathsToLink = ["/share/zsh"];
  };
}
