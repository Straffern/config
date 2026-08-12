{den, ...}: {
  den.aspects.desktop.addons.wlogout = {
    homeManager = {lib, ...}: {
      programs.wlogout = {
        enable = true;
        layout = [
          {
            label = "lock";
            action = "hyprlock";
            text = "Lock";
            keybind = "l";
          }
          {
            label = "hibernate";
            action = "systemctl hibernate";
            text = "Hibernate";
            keybind = "h";
          }
          {
            label = "logout";
            action = "loginctl terminate-user $USER";
            text = "Logout";
            keybind = "L";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "S";
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
            keybind = "s";
          }
          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
            keybind = "r";
          }
        ];
        style = builtins.readFile ./_assets/style.css;
      };

      xdg.configFile."wlogout/icons" = {
        recursive = true;
        source = ./_assets/icons;
      };
    };
  };
}
