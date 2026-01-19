{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.system.battery;

  # Auto-detect CPU vendor from hardware config
  # Check microcode settings or kernel modules for CPU type
  hasAmdMicrocode = config.hardware.cpu.amd.updateMicrocode or false;
  hasIntelMicrocode = config.hardware.cpu.intel.updateMicrocode or false;
  hasKvmAmd = builtins.elem "kvm-amd" config.boot.kernelModules;
  hasKvmIntel = builtins.elem "kvm-intel" config.boot.kernelModules;

  isAmd = hasAmdMicrocode || hasKvmAmd;
  isIntel = hasIntelMicrocode || hasKvmIntel;
in {
  options.${namespace}.system.battery = with types; {
    enable = mkEnableOption "Battery optimizations and utils.";

    battery =
      mkOpt str "BAT1" "The battery identifier in /sys/class/power_supply/.";

    powerManagement = mkOption {
      type = enum ["auto" "ppd" "auto-cpufreq" "tlp"];
      default = "auto";
      description = ''
        Power management daemon to use:
        - auto: PPD for AMD (recommended by Framework/AMD), auto-cpufreq for Intel
        - ppd: power-profiles-daemon (performance/balanced/power-saver profiles)
        - auto-cpufreq: Automatic CPU frequency scaling based on load/power source
        - tlp: Advanced power management with many tunables (not recommended for AMD 7040)
      '';
    };

    thermald = mkBoolOpt isIntel ''
      Enable Intel thermald for thermal management.
      Only useful on Intel CPUs - automatically enabled for Intel, disabled for AMD.
    '';

    disableNmiWatchdog = mkBoolOpt false ''
      Disable NMI watchdog for ~1W power savings.
      WARNING: When disabled, kernel lockups won't trigger automatic reboot.
      You'll need to manually power cycle on system freezes.
      Default: false (keep watchdog enabled for better UX on lockups).
    '';

    enableKernelTweaks = mkBoolOpt true ''
      Enable kernel sysctl tweaks for power saving:
      - Increase dirty writeback time (reduce disk wakeups)
    '';

    enableScheduler = mkBoolOpt true ''
      Enable System76 scheduler for better CPU cycle scheduling.
      Compatible with all power management daemons.
    '';

    lowBatteryNotification = {
      enable = mkBoolOpt true "Enable low battery notification.";
      threshold = mkOpt int 10 "Battery percentage threshold for notification.";
    };
  };

  config = mkIf cfg.enable {
    # Better scheduling for CPU cycles - thanks System76!!!
    # Compatible with PPD/TLP/auto-cpufreq, handles process scheduling not power management
    services.system76-scheduler.settings.cfsProfiles.enable =
      cfg.enableScheduler;

    environment.systemPackages = with pkgs; [
      powertop
      acpi
      power-profiles-daemon # provides powerprofilesctl
    ];

    # Automatically switch power profiles based on AC power state
    # Performance when plugged in, power-saver when on battery
    services.udev.extraRules = lib.mkIf config.services.power-profiles-daemon.enable ''
      # When AC adapter is plugged in - switch to performance
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
      # When AC adapter is unplugged - switch to power-saver
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    '';

    powerManagement.enable = true;

    # Power management daemon selection
    # PPD for AMD (Framework/AMD recommended), auto-cpufreq as fallback for Intel
    services.power-profiles-daemon.enable =
      if cfg.powerManagement == "auto"
      then isAmd || (!isIntel && !isAmd)
      else cfg.powerManagement == "ppd";

    services.auto-cpufreq = {
      enable =
        if cfg.powerManagement == "auto"
        then isIntel
        else cfg.powerManagement == "auto-cpufreq";
      settings = mkIf (cfg.powerManagement
        == "auto-cpufreq"
        || (cfg.powerManagement == "auto" && isIntel)) {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    services.tlp = {
      enable = cfg.powerManagement == "tlp";
      settings = mkIf (cfg.powerManagement == "tlp") {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        # USB autosuspend can cause issues, disable by default
        USB_AUTOSUSPEND = 0;
      };
    };

    # thermald is Intel-specific - only enable on Intel CPUs
    services.thermald.enable = cfg.thermald;

    # Kernel sysctl for power savings
    boot.kernel.sysctl = mkIf cfg.enableKernelTweaks ({
        # Increase dirty writeback time - reduces NVMe wakeups (default 500 = 5s)
        "vm.dirty_writeback_centisecs" = 6000;
      }
      // lib.optionalAttrs cfg.disableNmiWatchdog {
        # Disable NMI watchdog - saves ~1W but loses automatic reboot on lockups
        "kernel.nmi_watchdog" = 0;
      });

    # Low battery notification
    systemd.user.timers.notify-on-low-battery = mkIf cfg.lowBatteryNotification.enable {
      timerConfig.OnBootSec = "2m";
      timerConfig.OnUnitInactiveSec = "2m";
      timerConfig.Unit = "notify-on-low-battery.service";
      wantedBy = ["timers.target"];
    };

    systemd.user.services.notify-on-low-battery = mkIf cfg.lowBatteryNotification.enable {
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.battery}/capacity)
        export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.battery}/status)

        if [[ $battery_capacity -le ${
          toString cfg.lowBatteryNotification.threshold
        } && $battery_status = "Discharging" ]]; then
          ${pkgs.libnotify}/bin/notify-send --urgency=critical "$battery_capacity%: See you, space cowboy..."
        fi
      '';
    };
  };
}
