{den, ...}: {
  den.aspects.network.server.nixos = {pkgs, ...}: {
    environment.systemPackages = [pkgs.dnsutils];
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.network.wait-online.enable = false;
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };
}
