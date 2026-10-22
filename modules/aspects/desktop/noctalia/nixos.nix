{
  den,
  inputs,
  ...
}: {
  den.aspects.desktop.noctalia = {
    includes = [
      den.aspects.services.noctalia-greeter
      den.aspects.styles.monolisa
      den.aspects.development.mutable-source
    ];
    vmSmoke = [
      {
        name = "noctalia";
        description = "Noctalia shell is operational";
        phase = "session";
        script = ''
          assert login_user is not None, "Noctalia smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet noctalia.service"), timeout=120)
          # The IPC socket is keyed by WAYLAND_DISPLAY, which only the session environment carries.
          machine.wait_until_succeeds(user_command("sh -c 'WAYLAND_DISPLAY=$(systemctl --user show-environment | sed -n s/^WAYLAND_DISPLAY=//p) noctalia msg status'"), timeout=60)
        '';
      }
    ];
    nixos = {
      host,
      pkgs,
      ...
    }: {
      imports = [inputs.noctalia.nixosModules.default];
      config = {
        assertions = [
          {
            assertion = !(host.hasAspect den.aspects.desktop.dms);
            message = "Select one desktop shell: DMS or Noctalia.";
          }
        ];
        # NetworkManager, Bluetooth, UPower, and power-profiles-daemon back Noctalia's controls.
        programs.noctalia = {
          enable = true;
          recommendedServices.enable = true;
        };
        nix.settings = {
          substituters = ["https://noctalia.cachix.org"];
          trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
        };
        environment = {
          sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
          systemPackages = [pkgs.kdePackages.qt6ct];
        };
        fonts.packages = with pkgs; [
          noto-fonts
          source-serif
          noto-fonts-color-emoji
        ];
      };
    };
  };
}
