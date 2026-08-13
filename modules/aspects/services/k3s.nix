{
  den,
  inputs,
  ...
}: {
  den.aspects.services.k3s.nixos = {
    config,
    lib,
    host,
    ...
  }: {
    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = config.services.k3s.role != "agent" || config.services.k3s.serverAddr != null;
            message = "serverAddr must be set when role is 'agent'";
          }
        ];
        sops.secrets.k3s_token.sopsFile = inputs.self + "/secrets/suites/kubernetes.yaml";
        services.k3s = {
          enable = true;
          extraFlags = ''--kubelet-arg "node-ip=0.0.0.0"'';
        };
        networking.firewall.allowedUDPPorts = [
          53
          8472
        ];
        networking.firewall.allowedTCPPorts = [
          22
          53
          6443
          6444
          9000
          445
          139
        ];
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        environment.persistence."/persist".directories = [
          "/var/lib/rancher"
          "/var/lib/kubelet"
          "/var/lib/cni"
        ];
      })
    ];
  };
}
