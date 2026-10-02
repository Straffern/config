{den, ...}: {
  den.aspects.hardware.bluetooth.nixos = {
    lib,
    host,
    pkgs,
    ...
  }:
    lib.mkMerge [
      {
        services.blueman.enable = true;
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
          settings.General = {
            Experimental = true;
            KernelExperimental = true;
            JustWorksRepairing = "confirm";
          };
        };
        systemd.services.bluetooth-unblock = {
          description = "Unblock bluetooth rfkill so desktop shells can manage it";
          bindsTo = ["sys-subsystem-bluetooth-devices-hci0.device"];
          after = ["sys-subsystem-bluetooth-devices-hci0.device" "systemd-rfkill.service"];
          wantedBy = ["sys-subsystem-bluetooth-devices-hci0.device"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
          };
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        environment.persistence."/persist".directories = ["/var/lib/bluetooth"];
      })
    ];

  den.aspects.hardware.hidraw = {
    nixos = {
      users.groups.hidraw = {};
      services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="hidraw"'';
    };
    user.extraGroups = ["hidraw"];
  };
}
