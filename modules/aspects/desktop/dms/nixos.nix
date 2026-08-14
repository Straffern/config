{
  den,
  inputs,
  ...
}: {
  den.aspects.desktop.dms = {
    includes = [
      den.aspects.services.dankgreeter
      den.aspects.styles.monolisa
    ];
    vmSmoke = [
      {
        name = "dms";
        description = "Dank Material Shell is operational";
        phase = "session";
        script = ''
          assert login_user is not None, "DMS smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet dms.service"))
        '';
      }
      {
        name = "dms-theme";
        description = "DMS generates its Neovim theme adapters";
        phase = "session";
        script = ''
          assert login_user is not None, "DMS theme smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(f"test -s {login_home}/.config/nvim/colors/dms.lua")
          machine.wait_until_succeeds(f"test -s {login_home}/.config/nvim/lua/lualine/themes/dms.lua")
        '';
      }
    ];
    nixos = {
      lib,
      options,
      pkgs,
      ...
    }: {
      imports = [inputs.dms.nixosModules.default];
      config = lib.mkMerge [
        {
          environment = {
            sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
            systemPackages = [pkgs.kdePackages.qt6ct];
          };
          programs.dank-material-shell.enable = true;
          fonts.packages = with pkgs; [
            noto-fonts
            source-serif
            noto-fonts-color-emoji
          ];
        }
        (lib.optionalAttrs (options ? stylix.enable) {
          stylix.enable = lib.mkForce false;
        })
      ];
    };
  };
}
