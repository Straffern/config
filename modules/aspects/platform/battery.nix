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
  in {
    services = {
      # DMS switches power profiles itself; otherwise follow the AC state:
      # balanced when plugged in, power-saver on battery.
      udev.extraRules = lib.mkIf (!dmsEnabled) ''
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl --no-block start power-profile-ac.service"
      '';

      power-profiles-daemon.enable = true;
    };

    environment.systemPackages = with pkgs; [
      powertop
      acpi
      power-profiles-daemon # provides powerprofilesctl
    ];

    powerManagement.enable = true;

    systemd.services.power-profile-ac = lib.mkIf (!dmsEnabled) {
      description = "Set the power profile from the current AC state";
      after = ["power-profiles-daemon.service"];
      requires = ["power-profiles-daemon.service"];
      serviceConfig.Type = "oneshot";
      script = ''
        case "$(< /sys/class/power_supply/ACAD/online)" in
          1) ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced ;;
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
