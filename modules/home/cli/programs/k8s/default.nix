{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.programs.k8s;
in {
  options.${namespace}.cli.programs.k8s = {
    enable = mkEnableOption "Kubernetes tools";
  };

  config = mkIf cfg.enable {
    programs = { k9s = { enable = true; }; };

    home.packages = with pkgs; [
      kubectl
      kubectx
      kubelogin
      kubelogin-oidc
      stern
      kubernetes-helm
      kustomize
      fluxcd
      kubefwd
    ];
  };
}
