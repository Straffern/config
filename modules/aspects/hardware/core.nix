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
          };
        };
        systemd.services.bluetooth-unblock = {
          description = "Unblock bluetooth rfkill so desktop shells can manage it";
          after = ["bluetooth.service"];
          requires = ["bluetooth.service"];
          wantedBy = ["bluetooth.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
            ExecStartPost = "${pkgs.bluez}/bin/bluetoothctl power off";
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
