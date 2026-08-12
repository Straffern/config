{den, ...}: {
  den.aspects.cli.kubernetes.homeManager = {pkgs, ...}: {
    programs.k9s.enable = true;
    home.packages = with pkgs; [kubectl kubectx kubelogin kubelogin-oidc stern kubernetes-helm kustomize fluxcd kubefwd kaf];
  };
}
