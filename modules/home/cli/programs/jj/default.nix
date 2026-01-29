{
  pkgs,
  config,
  lib,
  namespace,
  inputs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.jj;
in {
  imports = [./aliases.nix ./revsets.nix];

  options.${namespace}.cli.programs.jj = with types; {
    enable = mkEnableOption "jujutsu";
    userName =
      mkOpt (nullOr str) "Alexander Flensborg"
      "The name appearing on the commits";
    email =
      mkOpt (nullOr str) "alex@flensborg.dev" "The email to use with git.";
    alias =
      mkOpt (nullOr str) "straffern"
      "An alias for your user. Eg. Account name.";
  };

  config = mkIf cfg.enable {
    home.packages = let
      ww = inputs.ww.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
      with pkgs; [
        # lazyjj
        jujutsu
        watchman
        difftastic
        inputs.jjui.packages.${pkgs.stdenv.hostPlatform.system}.default
        ww
        asgaard.jj-starship
        lumen
        asgaard.jj-ryu
      ];

    # ww shell integration (must run at shell init for cd wrapper)
    programs.zsh.initContent = lib.mkAfter ''
      # ww - jj workspace wrapper
      eval "$(ww init zsh)"
    '';

    # ww completion - pre-generated at build time (fast)
    xdg.configFile."zsh/completions/_ww".source = let
      ww = inputs.ww.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
      pkgs.runCommand "ww-zsh-completion" {} ''
        ${ww}/bin/ww completion zsh > $out
      '';

    programs.jujutsu = {
      enable = true;
      settings = {
        fsmonitor.backend = "watchman";
        fsmonitor.watchman.register-snapshot-trigger = true;

        user = {
          inherit (cfg) email;
          name = cfg.userName;
        };

        ui = {
          default-command = "worklog";
          pager = "delta";
          diff-editor = ["nvim" "-c" "DiffEditor $left $right $output"];
          diff.formatter = "difftastic";
          merge-editor = "vimdiff";

          # show-cryptographic-signatures = true;
        };

        merge-tools.difftastic = {
          program = "${pkgs.difftastic}/bin/difft";
          diff-args = ["--color=always" "$left" "$right"];
        };
        merge-tools.vimdiff = {
          merge-args = [
            "-f"
            "-d"
            "$output"
            "-M"
            "$left"
            "$base"
            "$right"
            "-c"
            "wincmd J"
            "-c"
            "set modifiable"
            "-c"
            "set write"
          ];
          program = "nvim";
          merge-tool-edits-conflict-markers = true;
        };

        colors = {
          commit_id = {
            # fg = "#${colors.base0A}";
            fg = "#0000ff";
            # bg = "#00008f";
            bold = true;
          }; # e.g., #00008f for blue
          change_id = {
            # fg = "#${colors.base0E}";
            fg = "#7f00ff";
            # bg = "#7f00ff";
            italic = true;
            bold = true;
          }; # e.g., #7f00ff for magenta
          "working_copy commit_id" = {underline = true;};
          "diff removed token" = {
            # bg = "#${colors.base08}";
            # fg = "#${colors.base05}";
            fg = "#ff0000";
            underline = true;
          }; # e.g., #ff0000 for red
          "diff added token" = {
            # bg = "#${colors.base0B}";
            # fg = "#${colors.base05}";
            fg = "#007f00";
            underline = true;
          }; # e.g., #00ff00 for green
        };

        signing = let
          gitCfg = config.programs.git.settings;
        in {
          backend = "ssh";
          behaviour =
            if gitCfg.commit.gpgsign
            then "own"
            else "never";
          key = gitCfg.user.signingkey;
        };

        revsets = {
          # Smart log revset showing your work with full context:
          # - @: current working copy
          # - trunk()..@: full path from trunk to your work (with ancestors for context)
          # - heads(trunk()): all branch heads for orientation
          log = "present(@) | ancestors(immutable_heads().., 2) | heads(immutable_heads())";
        };

        templates = {
          draft_commit_description = ''
            concat(
              description,
              surround(
                "\nJJ: Files:\n", "",
                indent("JJ:     ", diff.summary()),
              ),
              "\n",
              "JJ: ignore-rest\n",
              diff.git(),
            )
          '';
          git_push_bookmark =
            lib.mkDefault ''"${cfg.alias}/push-" ++ change_id.short()'';
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.email().local()";

          # Terminal hyperlinks
          "hyperlink(url, text)" = ''
            concat(
              raw_escape_sequence("\e]8;;" ++ url ++ "\e\\"),
              text,
              raw_escape_sequence("\e]8;;\e\\")
            )
          '';
          "github_url(change_id)" = ''
            "https://github.com/straffern/.dotfiles/pull/" ++ change_id.short()
          '';
        };

        git = {
          sign-on-push = true;
          private-commits = lib.mkDefault "blacklist()";
          write-change-id-header = true;
        };

        remotes.origin.auto-track-bookmarks = "glob:straffern/*";
      };
    };
  };
}
