{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.suites.common;
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

      # Persistence for "orphan" directories - apps without dedicated modules
      system.persistence.directories = [
        # Development tools
        ".beads" # bd issue tracker
        ".cargo" # Rust toolchain/cache

        # Authentication & credentials
        ".config/github-copilot" # Copilot auth

        # Applications
        ".config/Slack" # Slack workspace data
        ".config/blender" # Blender preferences
        ".n8n" # n8n workflow data
        ".local/share/livebook" # Livebook notebooks
      ];
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
  };
}
