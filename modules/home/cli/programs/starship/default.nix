{ config, lib, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.cli.programs.starship;
  jjCfg = config.${namespace}.cli.programs.jj; # Access JJ module config

  # Conditional JJ settings that only apply when JJ is enabled
  jjStarshipSettings = lib.mkIf jjCfg.enable {
    custom = {
      jj = {
        command = "${pkgs.asgaard.jj-starship}/bin/jj-starship";
        when = "jj-starship detect";
      };
    };
    # Disable built-in git modules in JJ repos to avoid conflicts
    git_branch = { disabled = false; };
    git_status = { disabled = false; };
  };
in {
  options.${namespace}.cli.programs.starship = {
    enable = mkEnableOption "Starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        palette = lib.mkDefault "custom";
        palettes.custom = {
          rosewater = "#${colors.base06}";
          flamingo = "#${colors.base0F}";
          pink = "#f6c2e7";
          mauve = "#${colors.base0E}";
          red = "#${colors.base08}";
          maroon = "#eba0ac";
          peach = "#${colors.base09}";
          yellow = "#${colors.base0A}";
          green = "#${colors.base0B}";
          teal = "#${colors.base0C}";
          sky = "#89dceb";
          sapphire = "#74c7ec";
          blue = "#${colors.base0D}";
          lavender = "#${colors.base07}";
          text = "#${colors.base05}";
          subtext1 = "#bac2de";
          subtext0 = "#a6adc8";
          overlay2 = "#9399b2";
          overlay1 = "#7f849c";
          overlay0 = "#6c7086";
          surface2 = "#${colors.base04}";
          surface1 = "#${colors.base03}";
          surface0 = "#${colors.base02}";
          base = "#${colors.base00}";
          mantle = "#${colors.base01}";
          crust = "#11111b";
        };
      };
      } // jjStarshipSettings; # Merge conditional JJ settings
    };
  };
}
