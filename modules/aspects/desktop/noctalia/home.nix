{
  den,
  inputs,
  ...
}: {
  # The cachix branch tracks commits Noctalia's CI has cached; no nixpkgs follows, so the cache hits.
  flake-file.inputs.noctalia.url = "github:noctalia-dev/noctalia/cachix";

  den.aspects.desktop.noctalia.homeManager = {
    config,
    host,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkAfter mkForce mkIf mkMerge;
    inherit (config.lib.mutableSources) source;

    niriEnabled = config.programs.niri.enable or false;
    hyprlandEnabled = host.hasAspect den.aspects.desktop.hyprland;
    configHome = config.xdg.configHome;

    # Template outputs that HM-managed configs include; seeded empty so includes resolve before the first render.
    themeFiles = {
      kitty = "${configHome}/kitty/themes/noctalia.conf";
      foot = "${configHome}/foot/themes/noctalia";
      alacritty = "${configHome}/alacritty/themes/noctalia.toml";
    };

    # Built-in templates for apps whose configs HM links read-only run hooks that append includes,
    # so render the same inputs as user templates and include their outputs declaratively instead.
    builtinTemplate = path: "${config.programs.noctalia.package}/share/noctalia/assets/templates/${path}";
    templates = (pkgs.formats.toml {}).generate "noctalia-templates.toml" {
      theme.templates = {
        enable_builtin_templates = true;
        builtin_ids = ["gtk3" "gtk4" "qt"];
        user =
          {
            kitty = {
              input_path = builtinTemplate "kitty/kitty.conf";
              output_path = themeFiles.kitty;
              post_hook = "pkill -USR1 kitty || true";
            };
            foot = {
              input_path = builtinTemplate "foot/foot";
              output_path = themeFiles.foot;
            };
            alacritty = {
              input_path = builtinTemplate "alacritty/alacritty.toml";
              output_path = themeFiles.alacritty;
            };
          }
          // lib.optionalAttrs hyprlandEnabled {
            hyprland = {
              input_path = builtinTemplate "hyprland/hyprland.lua";
              output_path = "${configHome}/hypr/noctalia.lua";
              post_hook = ''[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] || hyprctl reload'';
            };
          }
          // lib.optionalAttrs niriEnabled {
            niri = {
              input_path = builtinTemplate "niri/niri.kdl";
              output_path = "${configHome}/niri/noctalia.kdl";
            };
          };
      };
    };
  in {
    imports = [inputs.noctalia.homeModules.default];
    config = mkMerge [
      {
        programs.noctalia = {
          enable = true;
          systemd.enable = true;
        };
        # Start under Niri or Hyprland, not gamescope.
        systemd.user.services.noctalia.Unit.ConditionEnvironment =
          lib.optional niriEnabled "|XDG_CURRENT_DESKTOP=niri"
          ++ lib.optional hyprlandEnabled "|XDG_CURRENT_DESKTOP=Hyprland";

        # `mutable on` links these to the repo, so Settings writes through settings.toml into ~/.dotfiles.
        xdg.configFile = {
          "noctalia/config.toml".source = source ./_config/config.toml;
          "noctalia/templates.toml".source = templates;
          "xdg-terminals.list".text = "kitty.desktop\n";
        };
        xdg.stateFile."noctalia/settings.toml".source = source ./_config/settings.toml;

        programs.kitty.extraConfig = mkAfter "include themes/noctalia.conf";
        programs.foot.settings.main.include = themeFiles.foot;
        programs.alacritty.settings.general.import = [themeFiles.alacritty];

        home.activation.noctaliaThemeFiles = lib.hm.dag.entryAfter ["writeBoundary"] (
          lib.concatMapStrings (file: ''
            if [ ! -e ${lib.escapeShellArg file} ]; then
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 /dev/null ${lib.escapeShellArg file}
            fi
          '') (builtins.attrValues themeFiles)
        );

        # GTK apps need a real theme package; the gtk templates only overlay colors.
        home.packages = with pkgs; [
          adw-gtk3
          xdg-terminal-exec
          phinger-cursors
        ];
      }

      (mkIf hyprlandEnabled {
        xdg.configFile."hypr/shell.lua".source = source ./_config/hypr/shell.lua;
      })

      (mkIf niriEnabled {
        xdg.configFile.niri-config.target = mkForce "niri/hm.kdl";
        xdg.configFile.niri-config-noctalia = {
          target = "niri/config.kdl";
          source = source ./_config/niri/config.kdl;
        };
      })
    ];
  };
}
