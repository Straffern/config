{den, ...}: {
  den.aspects.hardware.bluetooth.nixos = {
    host,
    lib,
    pkgs,
    ...
  }: {
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
    environment.persistence."/persist".directories =
      lib.mkIf (host.hasAspect den.aspects.platform.impermanence)
      ["/var/lib/bluetooth"];
  };

  den.aspects.hardware.nvidia.nixos = {config, ...}: {
    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    environment.variables.CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    environment.shellAliases.nvidia-settings = "nvidia-settings --config='$XDG_CONFIG_HOME'/nvidia/settings";
    environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  };

  den.aspects.hardware.hidraw = {
    nixos = {
      users.groups.hidraw = {};
      services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="hidraw"'';
    };
    user.extraGroups = ["hidraw"];
  };
}
