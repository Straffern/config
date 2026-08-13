{
  den,
  inputs,
  ...
}: {
  den.aspects.cli.hunk.homeManager = {
    inputs',
    pkgs,
    ...
  }: {
    imports = [inputs.hunk.homeManagerModules.default];
    programs.hunk = {
      enable = true;
      package = inputs'.hunk.packages.default;
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
      hd = [
        "util"
        "exec"
        "--"
        "hunk"
        "diff"
      ];
      hs = [
        "util"
        "exec"
        "--"
        "hunk"
        "show"
      ];
      hdw = [
        "util"
        "exec"
        "--"
        "hunk"
        "diff"
        "--watch"
      ];
    };
  };
  flake-file.inputs.hunk.url = "github:modem-dev/hunk";
}
