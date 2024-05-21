{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.system.battery;
in {
  options.system.battery = with types; {
    enable = mkBoolOpt false "Whether or not to enable battery optimizations and utils.";
    battery = mkOpt str "BAT1" "The battery on the device.";
  };

  config = mkIf cfg.enable {
    # Better scheduling for CPU cycles - thanks System76!!!
    services.system76-scheduler.settings.cfsProfiles.enable = true;


    environment.systemPackages = with pkgs; [
      powertop
      acpi
      # tlp
    ];


    powerManagement.enable = true;

    # Enable TLP (better than gnomes internal power manager)
    # services.tlp = {
    #   enable = true;
    #   settings = {
    #     USB_AUTOSUSPEND = 0;
    #     CPU_BOOST_ON_AC = 1;
    #     CPU_BOOST_ON_BAT = 0;
    #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    #   };
    # };

    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };


    systemd.user.timers.notify-on-low-battery = {
      timerConfig.OnBootSec = "2m";
      timerConfig.OnUnitInactiveSec = "2m";
      timerConfig.Unit = "notify-on-low-battery.service";
      wantedBy = [ "timers.target" ];
    };

    systemd.user.services.notify-on-low-battery = {
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.battery}/capacity)
        export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.battery}/status)

        if [[ $battery_capacity -le 10 && $battery_status = "Discharging" ]]; then
          ${pkgs.libnotify}/bin/notify-send --urgency=critical "$battery_capacity%: See you, space cowboy..."
            fi
            '';
    };

    # Disable GNOMEs power management
    services.power-profiles-daemon.enable = false;

    # Enable powertop
    # powerManagement.powertop.enable = true;

    # Enable thermald (only necessary if on Intel CPUs)
    services.thermald.enable = true;
  };
}
