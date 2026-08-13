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

      power-profiles-daemon.enable = isAmd || !isIntel;

      auto-cpufreq = {
        enable = isIntel;
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

    systemd.user.timers.notify-on-low-battery = {
      timerConfig = {
        OnBootSec = "2m";
        OnUnitInactiveSec = "2m";
        Unit = "notify-on-low-battery.service";
      };
      wantedBy = ["timers.target"];
    };

    systemd.user.services.notify-on-low-battery = {
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
