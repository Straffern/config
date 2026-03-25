{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.hardware.bluetoothctl;
in {
  options.${namespace}.hardware.bluetoothctl = {
    enable = mkEnableOption "Enable bluetooth service and packages";
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings = {General = {Experimental = true;};};
      };
    };

    # powerOnBoot = false causes bluez to leave the adapter rfkill soft-blocked.
    # Desktop shells (DMS/QuickShell) refuse to toggle a blocked adapter —
    # they can only toggle between Disabled ↔ Enabled, not unblock rfkill.
    # This service removes the soft-block so the GUI toggle works, then
    # immediately powers the adapter off so bluetooth stays off on boot.
    systemd.services.bluetooth-unblock = {
      description = "Unblock bluetooth rfkill so desktop shells can manage it";
      after = ["bluetooth.service"];
      requires = ["bluetooth.service"];
      wantedBy = ["bluetooth.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        # Adapter auto-powers after unblock; turn it back off.
        ExecStartPost = "${pkgs.bluez}/bin/bluetoothctl power off";
      };
    };

    # Allow desktop users (wheel) to manage bluetooth adapters, devices,
    # and rfkill without authentication. Bluez itself doesn't gate on polkit,
    # but blueman-mechanism (rfkill toggle) does when built with polkit support,
    # and some desktop shells rely on polkit for privileged bluetooth operations.
    # security.polkit.extraConfig = ''
    #   polkit.addRule(function(action, subject) {
    #     if ((action.id == "org.blueman.network.setup" ||
    #          action.id == "org.blueman.dhcp.client" ||
    #          action.id == "org.blueman.rfkill.setstate" ||
    #          action.id == "org.blueman.pppd.pppconnect") &&
    #         subject.isInGroup("wheel"))
    #     {
    #       return polkit.Result.YES;
    #     }
    #   });
    # '';

    # Persist paired device keys and configurations
    ${namespace}.system.impermanence.directories = ["/var/lib/bluetooth"];
  };
}
