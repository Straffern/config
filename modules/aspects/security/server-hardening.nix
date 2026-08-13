{den, ...}: {
  den.aspects.security.server-hardening.nixos = {
    security.sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
      extraConfig = "Defaults lecture = never";
    };
    users.mutableUsers = false;
    systemd.enableEmergencyMode = false;
  };
}
