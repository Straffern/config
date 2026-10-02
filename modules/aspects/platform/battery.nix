{den, ...}: {
  den.aspects.platform.battery.nixos = {
    config,
    host,
    lib,
    pkgs,
    ...
  }: let
    dmsEnabled = host.hasAspect den.aspects.desktop.dms;
    noctaliaEnabled = config.programs.noctalia.enable or false;
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
      udev.extraRules = lib.mkIf (config.services.power-profiles-daemon.enable && !dmsEnabled) ''
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl --no-block start power-profile-ac.service"
      '';

      power-profiles-daemon.enable = dmsEnabled || isAmd || !isIntel;

      auto-cpufreq = {
        enable = isIntel && !dmsEnabled;
        settings = lib.mkIf isIntel {
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

      thermald.enable = isIntel;
    };

    environment.systemPackages = with pkgs; [
      powertop
      acpi
      power-profiles-daemon # provides powerprofilesctl
    ];

    powerManagement.enable = true;

    boot.kernel.sysctl."vm.dirty_writeback_centisecs" = 6000;

    systemd.services.power-profile-ac = lib.mkIf (config.services.power-profiles-daemon.enable && !dmsEnabled) {
      description = "Set the power profile from the current AC state";
      after = ["power-profiles-daemon.service"];
      requires = ["power-profiles-daemon.service"];
      serviceConfig.Type = "oneshot";
      script = ''
        case "$(< /sys/class/power_supply/ACAD/online)" in
          1) ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance ;;
          0) ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver ;;
        esac
      '';
    };

    systemd.user.timers.notify-on-low-battery = lib.mkIf (!dmsEnabled && !noctaliaEnabled) {
      timerConfig = {
        OnBootSec = "2m";
        OnUnitInactiveSec = "2m";
        Unit = "notify-on-low-battery.service";
      };
      wantedBy = ["timers.target"];
    };

    systemd.user.services.notify-on-low-battery = lib.mkIf (!dmsEnabled && !noctaliaEnabled) {
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        for battery in /sys/class/power_supply/BAT*; do
          [[ -r "$battery/capacity" && -r "$battery/status" ]] || continue
          battery_capacity=$(<"$battery/capacity")
          battery_status=$(<"$battery/status")

          if [[ $battery_capacity -le 10 && $battery_status = "Discharging" ]]; then
            ${pkgs.libnotify}/bin/notify-send --urgency=critical "$battery_capacity%: See you, space cowboy..."
          fi
        done
      '';
    };
  };
}
