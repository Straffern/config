# Fail2ban — intrusion prevention via log-based ban rules.
#
# Monitors auth logs and bans IPs that show malicious signs (brute-force SSH,
# repeated auth failures, etc). Bans are progressive: short ban first, then
# escalating for repeat offenders via the recidive jail.
{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.security.fail2ban;
in {
  options.${namespace}.security.fail2ban = {
    enable = mkEnableOption "Fail2ban intrusion prevention";

    maxRetry = mkOption {
      type = types.int;
      default = 3;
      description = "Number of failures before a ban.";
    };

    banTime = mkOption {
      type = types.str;
      default = "1h";
      description = "Default ban duration. Supports fail2ban time syntax (e.g. 1h, 30m, 1d).";
    };

    findTime = mkOption {
      type = types.str;
      default = "10m";
      description = "Window in which maxRetry failures trigger a ban.";
    };

    ignoreIPs = mkOption {
      type = types.listOf types.str;
      default = [
        "127.0.0.0/8"
        "::1"
      ];
      description = "IPs/CIDRs that are never banned. Add your Tailscale subnet here if desired.";
    };

    extraJails = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional fail2ban jail configurations (attrset merged into services.fail2ban.jails).";
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;

      maxretry = cfg.maxRetry;
      bantime = cfg.banTime;

      ignoreIP = cfg.ignoreIPs;

      bantime-increment = {
        enable = true;
        maxtime = "168h"; # Cap at 1 week
        factor = "4"; # Each repeat offense 4x longer
        overalljails = true; # Track across all jails
      };

      jails =
        {
          # SSH — the primary attack vector on any VPS
          sshd = {
            settings = {
              enabled = true;
              port = "ssh";
              filter = "sshd[mode=aggressive]";
              maxretry = cfg.maxRetry;
              findtime = cfg.findTime;
            };
          };
        }
        // cfg.extraJails;
    };

    # Persist ban database across reboots (impermanence-safe)
    ${namespace}.system.impermanence.directories = ["/var/lib/fail2ban"];
  };
}
