{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.development;
in {
  options.${namespace}.suites.development = {
    enable = mkEnableOption "Development configuration";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ btop ];
    ${namespace} = {
      cli = {
        editors.neovim = enabled;
        # multiplexers.zellij = enabled;

        programs = {
          # attic = enabled;
          # atuin = enabled;
          bat = enabled;
          bottom = enabled;
          db = enabled;
          direnv = enabled;
          devenv = enabled;
          eza = enabled;
          fzf = enabled;
          git = enabled;
          gpg = enabled;
          htop = enabled;
          k8s = enabled;
          modern-unix = enabled;
          network-tools = enabled;
          nix-index = enabled;
          podman = enabled;
          ssh = enabled;
          starship = enabled;
          yazi = enabled;
          zoxide = enabled;
        };
      };
    };
  };
}
