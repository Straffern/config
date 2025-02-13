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
      browsers.firefox = enabled;
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
      optinix

      (hiPrio parallel)
      moreutils
      nvtopPackages.amd
      unzip
      gnupg

      showmethekey
    ];
  };
}
