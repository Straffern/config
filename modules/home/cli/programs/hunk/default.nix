{
  config,
  lib,
  namespace,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.programs.hunk;
in {
  options.${namespace}.cli.programs.hunk = {
    enable = mkEnableOption "hunk";
  };

  config = mkIf cfg.enable {
    programs.hunk = {
      enable = true;
      package = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
      enableGitIntegration = false;
      settings = {
        theme = "midnight";
        mode = "auto";
        vcs = "jj";
        exclude_untracked = false;
        line_numbers = true;
        wrap_lines = false;
        hunk_headers = true;
        agent_notes = true;
      };
    };

    programs.git.settings.alias = {
      hdiff = ''-c core.pager="hunk pager" diff'';
      hshow = ''-c core.pager="hunk pager" show'';
      hlog = ''-c core.pager="hunk pager" log -p'';
    };

    programs.jujutsu.settings.aliases = {
      hd = ["util" "exec" "--" "hunk" "diff"];
      hs = ["util" "exec" "--" "hunk" "show"];
      hdw = ["util" "exec" "--" "hunk" "diff" "--watch"];
    };
  };
}
