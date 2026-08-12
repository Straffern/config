{den, ...}: {
  den.aspects.profiles.server = {
    includes = [
      den.aspects.profiles.common
      den.aspects.network.avahi
      den.aspects.services.tailscale
      den.aspects.security.fail2ban
    ];
    nixos = {
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = [
        pkgs.nfs-utils
        pkgs.openiscsi
        pkgs.dnsutils
      ];
      environment.variables.BROWSER = "echo";
      environment.stub-ld.enable = lib.mkDefault false;
      security.sudo = {
        wheelNeedsPassword = false;
        execWheelOnly = true;
        extraConfig = "Defaults lecture = never";
      };
      documentation = {
        enable = lib.mkDefault false;
        info.enable = lib.mkDefault false;
        man.enable = lib.mkDefault false;
        nixos.enable = lib.mkDefault false;
      };
      fonts.fontconfig.enable = lib.mkDefault false;
      time.timeZone = lib.mkDefault "UTC";
      users.mutableUsers = false;
      systemd.services.NetworkManager-wait-online.enable = false;
      systemd.network.wait-online.enable = false;
      systemd.tmpfiles.rules = ["L+ /usr/local/bin - - - - /run/current-system/sw/bin/"];
      systemd.enableEmergencyMode = false;
      systemd.settings.Manager = {
        RuntimeWatchdogSec = "20s";
        RebootWatchdogSec = "30s";
      };
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };
  };
}
