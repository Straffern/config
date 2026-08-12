{
  den,
  inputs,
  ...
}: {
  den.aspects.services.k3s.nixos = {
    host,
    lib,
    ...
  }: {
    config = {
      sops.secrets.k3s_token.sopsFile = inputs.self + "/secrets/suites/kubernetes.yaml";
      services.k3s = {
        enable = true;
        extraFlags = ''--kubelet-arg "node-ip=0.0.0.0"'';
      };
      environment.persistence."/persist".directories =
        lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
        [
          "/var/lib/rancher"
          "/var/lib/kubelet"
          "/var/lib/cni"
        ];
    };
  };
}
