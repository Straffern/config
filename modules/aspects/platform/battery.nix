{den, ...}: {
  den.aspects.platform.battery.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Detect CPU vendor from hardware configuration.
    # Check microcode settings or kernel modules for CPU type
    hasAmdMicrocode = config.hardware.cpu.amd.updateMicrocode or false;
    hasIntelMicrocode = config.hardware.cpu.intel.updateMicrocode or false;
    hasKvmAmd = builtins.elem "kvm-amd" config.boot.kernelModules;
    hasKvmIntel = builtins.elem "kvm-intel" config.boot.kernelModules;

    isAmd = hasAmdMicrocode || hasKvmAmd;
    isIntel = hasIntelMicrocode || hasKvmIntel;
  in {
    # Better scheduling for CPU cycles - thanks System76!!!
    # Compatible with PPD/TLP/auto-cpufreq, handles process scheduling not power management
    services = {
      system76-scheduler.settings.cfsProfiles.enable = true;

      # Automatically switch power profiles based on AC power state
      # Performance when plugged in, power-saver when on battery
      udev.extraRules = lib.mkIf config.services.power-profiles-daemon.enable ''
        # When AC adapter is plugged in - switch to performance
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
        # When AC adapter is unplugged - switch to power-saver
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
      '';

      # Power management daemon selection
      # PPD for AMD (Framework/AMD recommended), auto-cpufreq as fallback for Intel
      power-profiles-daemon.enable =
        if "auto" == "auto"
        then isAmd || (!isIntel && !isAmd)
        else "auto" == "ppd";

      auto-cpufreq = {
        enable =
          if "auto" == "auto"
          then isIntel
          else "auto" == "auto-cpufreq";
        settings = lib.mkIf ("auto"
          == "auto-cpufreq"
          || ("auto" == "auto" && isIntel)) {
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

      tlp = {
        enable = "auto" == "tlp";
        settings = lib.mkIf ("auto" == "tlp") {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          # USB autosuspend can cause issues, disable by default
          USB_AUTOSUSPEND = 0;
        };
      };

      # thermald is Intel-specific - only enable on Intel CPUs
      thermald.enable = isIntel;
    };

    environment.systemPackages = with pkgs; [
      powertop
      acpi
      power-profiles-daemon # provides powerprofilesctl
    ];

    powerManagement.enable = true;

    # Kernel sysctl for power savings
    boot.kernel.sysctl = lib.mkIf true ({
        # Increase dirty writeback time - reduces NVMe wakeups (default 500 = 5s)
        "vm.dirty_writeback_centisecs" = 6000;
      }
      // lib.optionalAttrs false {
        # Disable NMI watchdog - saves ~1W but loses automatic reboot on lockups
        "kernel.nmi_watchdog" = 0;
      });

    # Low battery notification
    systemd.user.timers.notify-on-low-battery = lib.mkIf true {
      timerConfig = {
        OnBootSec = "2m";
        OnUnitInactiveSec = "2m";
        Unit = "notify-on-low-battery.service";
      };
      wantedBy = ["timers.target"];
    };

    systemd.user.services.notify-on-low-battery = lib.mkIf true {
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT1/capacity)
        export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT1/status)

        if [[ $battery_capacity -le ${
          toString 10
        } && $battery_status = "Discharging" ]]; then
          ${pkgs.libnotify}/bin/notify-send --urgency=critical "$battery_capacity%: See you, space cowboy..."
        fi
      '';
    };
  };
}
