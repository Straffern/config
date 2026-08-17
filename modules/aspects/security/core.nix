{den, ...}: {
  den.aspects.security = {
    fail2ban.nixos = {
      lib,
      host,
      ...
    }:
      lib.mkMerge [
        {
          services.fail2ban = {
            enable = true;
            maxretry = 3;
            bantime = "1h";
            ignoreIP = [
              "127.0.0.0/8"
              "::1"
            ];
            bantime-increment = {
              enable = true;
              maxtime = "168h";
              factor = "4";
              overalljails = true;
            };
            jails.sshd.settings = {
              enabled = true;
              port = "ssh";
              filter = "sshd[mode=aggressive]";
              maxretry = 3;
              findtime = "10m";
            };
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          environment.persistence."/persist".directories = ["/var/lib/fail2ban"];
        })
      ];
    audit.nixos = {pkgs, ...}: {
      security.audit = {
        enable = true;
        rules = "";
      };
      environment.systemPackages = [pkgs.audit];
      boot.kernelParams = [
        "audit=1"
        "audit_backlog_limit=8192"
      ];
      boot.initrd.systemd.enable = true;
      systemd.services.auditd.serviceConfig.ExecStartPost = ["${pkgs.audit}/bin/auditctl -e 1"];
    };

    apparmor.nixos = {pkgs, ...}: {
      security.apparmor = {
        enable = true;
        packages = [
          pkgs.apparmor-utils
          pkgs.apparmor-bin-utils
          pkgs.apparmor-profiles
        ];
        profiles = {};
        killUnconfinedConfinables = true;
      };
      boot.kernelParams = [
        "apparmor=1"
        "security=apparmor"
        "lsm=landlock,lockdown,yama,apparmor,bpf"
      ];
      boot.initrd.systemd.enable = true;
      systemd.services.apparmor.serviceConfig.ExecStart = [
        ""
        "${pkgs.apparmor-bin-utils}/bin/apparmor_parser --enforce -rKTEX"
      ];
      environment.systemPackages = [
        pkgs.apparmor-utils
        pkgs.apparmor-bin-utils
        pkgs.apparmor-profiles
      ];
      system.activationScripts.apparmor = ''echo "AppArmor enabled in enforce mode"'';
    };

    yubikey.nixos = {pkgs, ...}: {
      services = {
        pcscd.enable = true;
        udev.extraRules = ''
          ACTION=="remove",\
           ENV{ID_BUS}=="usb",\
           ENV{ID_MODEL_ID}=="0407",\
           ENV{ID_VENDOR_ID}=="1050",\
           ENV{ID_VENDOR}=="Yubico",\
           RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';
      };
      security.pam.services = {
        swaylock.u2fAuth = true;
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    };
  };
}
