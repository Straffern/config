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
        name = "dms-state-migration";
        description = "Home Manager adopts DMS and GTK files from the previous generation";
        phase = "boot";
        module = {vmSmoke, ...}: let
          user = vmSmoke.loginUser;
          home = "/home/${user}";
        in {
          systemd.tmpfiles.rules = [
            "d ${home} 0755 ${user} users -"
            "d ${home}/.config 0755 ${user} users -"
            "d ${home}/.config/gtk-3.0 0755 ${user} users -"
            "f ${home}/.config/gtk-3.0/settings.ini 0644 ${user} users - legacy"
            "d ${home}/.config/DankMaterialShell 0755 ${user} users -"
            "f ${home}/.config/DankMaterialShell/settings.json.pre-home-manager 0644 ${user} users - {\"userSetting\":\"preserved\"}"
            "d ${home}/.local 0755 ${user} users -"
            "d ${home}/.local/state 0755 ${user} users -"
            "d ${home}/.local/state/DankMaterialShell 0755 ${user} users -"
            "f ${home}/.local/state/DankMaterialShell/session.json.pre-home-manager 0644 ${user} users - {\"wallpaperPath\":\"${home}/Pictures/chosen.png\"}"
          ];
        };
        script = ''
          assert login_user is not None, "DMS state migration requires vmSmoke.loginUser"
          machine.wait_for_unit(f"home-manager-{login_user}.service")
          machine.succeed(f"grep -Fx legacy {login_home}/.config/gtk-3.0/settings.ini.pre-home-manager")
          machine.succeed(f"test -f {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"test ! -L {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"runuser -u {login_user} -- test -w {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"grep -F '\"userSetting\": \"preserved\"' {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"grep -F '\"runDmsMatugenTemplates\": true' {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"grep -F '\"matugenTemplateNeovim\": true' {login_home}/.config/DankMaterialShell/settings.json")
          machine.succeed(f"test ! -e {login_home}/.config/DankMaterialShell/settings.json.pre-home-manager")
          machine.succeed(f"test -f {login_home}/.local/state/DankMaterialShell/session.json")
          machine.succeed(f"test ! -L {login_home}/.local/state/DankMaterialShell/session.json")
          machine.succeed(f"runuser -u {login_user} -- test -w {login_home}/.local/state/DankMaterialShell/session.json")
          machine.succeed(f"grep -F '\"wallpaperPath\":\"{login_home}/Pictures/chosen.png\"' {login_home}/.local/state/DankMaterialShell/session.json")
          machine.succeed(f"test ! -e {login_home}/.local/state/DankMaterialShell/session.json.pre-home-manager")
        '';
      }
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
      host,
      pkgs,
      ...
    }: {
      imports = [inputs.dms.nixosModules.default];
      config = {
        assertions = [
          {
            assertion = !(host.hasAspect den.aspects.styles.stylix);
            message = "DMS and Stylix cannot be selected together.";
          }
        ];
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
      };
    };
  };
}
