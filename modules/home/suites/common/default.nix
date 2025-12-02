{ lib, pkgs, config, namespace, osConfig ? { }, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.common;
  persistenceEnabled = osConfig.${namespace}.system.impermanence.enable or false;
in {
  options.${namespace}.suites.common = {
    enable = lib.mkEnableOption "Enable common configuration";
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      # browsers.firefox = enabled;
      browsers.brave = enabled;
      system.nix = enabled;

      cli = {
        terminals.kitty = enabled;
        shells.zsh = enabled;
      };
      security.sops = enabled;
      styles.stylix = enabled;

      programs = { guis = enabled; };
    };

    # TODO: move this to a separate module
    home.packages = with pkgs; [
      keymapp

      src-cli
      # optinix

      (lib.hiPrio parallel)
      moreutils
      nvtopPackages.amd
      unzip
      gnupg

      showmethekey
    ];

    # Persistence for "orphan" directories - apps without dedicated modules
    home.persistence."/persist/home/${config.home.username}" = mkIf persistenceEnabled {
      allowOther = true;
      directories = [
        # Development tools
        ".beads" # bd issue tracker
        ".cargo" # Rust toolchain/cache

        # Authentication & credentials
        ".config/gh" # GitHub CLI auth
        ".config/github-copilot" # Copilot auth

        # Applications
        ".config/Slack" # Slack workspace data
        ".config/blender" # Blender preferences
        ".n8n" # n8n workflow data
        ".local/share/livebook" # Livebook notebooks
      ];
    };
  };
}
