{ config, lib, pkgs, namespace, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.security.apparmor;
in {
  options.${namespace}.security.apparmor = {
    enable = mkEnableOption "AppArmor";
    
    enforceMode = mkOption {
      type = types.enum [ "enforce" "complain" "disabled" ];
      default = "enforce";
      description = "The default AppArmor enforcement mode";
    };
    
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional AppArmor tools and utilities";
    };
    
    extraProfiles = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Additional AppArmor profiles to install";
    };
  };

  config = mkIf cfg.enable {
    # Enable AppArmor at the system level
    security.apparmor = {
      enable = true;
      packages = cfg.extraPackages;
      profiles = cfg.extraProfiles;
      killUnconfinedConfinables = cfg.enforceMode == "enforce";
    };
    
    # Add AppArmor kernel parameters
    boot.kernelParams = [
      "apparmor=1"
      "security=apparmor"
      "lsm=landlock,lockdown,yama,apparmor,bpf"
    ];
    
    # Set the default enforcement mode
    boot.initrd.systemd.enable = true;
    systemd.services.apparmor.serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.apparmor-bin-utils}/bin/apparmor_parser --${cfg.enforceMode} -rKTEX"
      ];
    };
    
    # Install AppArmor utilities
    environment.systemPackages = with pkgs; [
      apparmor-utils
      apparmor-bin-utils
      apparmor-profiles
    ] ++ cfg.extraPackages;
    
    # Add a log message about the AppArmor setup
    system.activationScripts.apparmor = ''
      echo "AppArmor enabled in ${cfg.enforceMode} mode"
    '';
  };
}