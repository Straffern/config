{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.gh;
in {
  options.${namespace}.cli.programs.gh = {
    enable = mkEnableOption "GitHub CLI";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
      gitCredentialHelper.enable = true;
      extensions = with pkgs; [gh-dash gh-eco asgaard.gh-fork-cleanup];
    };

    ${namespace}.system.persistence.directories = [".config/gh"];
  };
}
