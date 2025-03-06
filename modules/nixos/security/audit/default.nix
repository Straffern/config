{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.security.audit;
in {
  options.${namespace}.security.audit = {
    enable = mkEnableOption "Linux Audit Framework";
    
    backlogLimit = mkOption {
      type = types.int;
      default = 8192;
      description = "Maximum number of outstanding audit buffers allowed";
    };
    
    rateLimit = mkOption {
      type = types.int;
      default = 0;
      description = "Messages rate limit (0 = no limit)";
    };
    
    rules = mkOption {
      type = types.lines;
      default = "";
      description = "Additional audit rules";
      example = ''
        # Log all commands executed by root
        -a exit,always -F arch=b64 -F euid=0 -S execve -k rootcmd
        
        # Log changes to passwd/group/shadow
        -w /etc/passwd -p wa -k identity
        -w /etc/group -p wa -k identity
        -w /etc/shadow -p wa -k identity
      '';
    };
    
    logRotate = {
      enable = mkEnableOption "Audit log rotation";
      
      frequency = mkOption {
        type = types.str;
        default = "weekly";
        description = "How often to rotate logs";
      };
      
      keep = mkOption {
        type = types.int;
        default = 4;
        description = "Number of rotated logs to keep";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the Linux audit framework
    security.auditd = {
      enable = true;
      extraConfig = ''
        # Basic configuration
        log_file = /var/log/audit/audit.log
        log_format = RAW
        flush = INCREMENTAL_ASYNC
        freq = 50
        max_log_file = 8
        num_logs = 5
        priority_boost = 4
        disp_qos = lossy
        dispatcher = /sbin/audispd
        name_format = NONE
        ##max_log_file_action = ROTATE
        space_left = 75
        space_left_action = SYSLOG
        verify_email = yes
        action_mail_acct = root
        admin_space_left = 50
        admin_space_left_action = SUSPEND
        disk_full_action = SUSPEND
        disk_error_action = SUSPEND
        
        # Performance settings
        write_logs = yes
        log_group = root
        backlog_limit = ${toString cfg.backlogLimit}
        rate_limit = ${toString cfg.rateLimit}
      '';
      
      # Add custom rules if provided
      rules = cfg.rules;
    };
    
    # Install audit utilities
    environment.systemPackages = with pkgs; [
      audit
      auditd
    ];
    
    # Setup logrotate if enabled
    services.logrotate = mkIf cfg.logRotate.enable {
      enable = true;
      settings = {
        "/var/log/audit/audit.log" = {
          frequency = cfg.logRotate.frequency;
          rotate = cfg.logRotate.keep;
          create = "0600 root root";
          missingok = true;
          compress = true;
          postrotate = ''
            /bin/systemctl kill -s SIGUSR1 auditd.service
          '';
        };
      };
    };
    
    # Add kernel parameters for auditing
    boot.kernelParams = [
      "audit=1"
      "audit_backlog_limit=${toString cfg.backlogLimit}"
    ];
    
    # Enable immediate reporting of audit events
    boot.initrd.systemd.enable = true;
    systemd.services.auditd = {
      serviceConfig = {
        ExecStartPost = [
          "${pkgs.audit}/bin/auditctl -e 1"
        ];
      };
    };
  };
}