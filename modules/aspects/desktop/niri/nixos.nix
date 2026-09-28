{den, ...}: {
  den.aspects.desktop.niri = {
    vmSmoke = [
      {
        name = "niri";
        description = "Niri exposes an output and Xwayland Satellite is operational";
        phase = "session";
        module = {
          lib,
          pkgs,
          ...
        }: {
          # QEMU's deterministic 2D virtio-gpu exposes llvmpipe. Upstream Niri
          # rejects software EGL due to unsafe mixed-renderer imports; this VM
          # has one software renderer and no dmabuf device sharing.
          programs.niri.package = lib.mkForce (pkgs.niri.overrideAttrs (old: {
            patches = (old.patches or []) ++ [./_assets/allow-software-renderer.patch];
          }));
        };
        script = ''
          assert login_user is not None, "Niri smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet niri.service"))
          machine.wait_until_succeeds(f"pgrep -u {login_uid} -f '/xwayland-satellite'")
          machine.wait_until_succeeds(user_command("sh -c 'NIRI_SOCKET=$(find /run/user/$(id -u) -maxdepth 1 -name \"niri*.sock\" -print -quit); export NIRI_SOCKET; niri msg --json outputs | jq -e \"length > 0 and all(.[]; .current_mode != null and .logical != null)\"'"), timeout=120)
        '';
      }
    ];

    nixos = {
      config,
      lib,
      options,
      pkgs,
      ...
    }: {
      config = lib.mkMerge [
        {
          environment.sessionVariables.NIXOS_OZONE_WL = "1";
          programs.niri = {
            enable = true;
            package = pkgs.niri;
          };
        }
        (lib.optionalAttrs (options ? programs.dms-greeter.enable) {
          programs.dms-greeter.compositor.name = lib.mkIf config.programs.dms-greeter.enable "niri";
        })
      ];
    };
  };
}
