{den, ...}: {
  den.aspects.desktop.niri = {
    vmSmoke = [
      {
        name = "niri";
        description = "Niri and Xwayland Satellite are operational";
        phase = "session";
        script = ''
          assert login_user is not None, "Niri smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet niri.service"))
          machine.wait_until_succeeds(f"pgrep -u {login_uid} -f '/xwayland-satellite'")
        '';
      }
    ];

    nixos = {pkgs, ...}: {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };
    };
  };
}
