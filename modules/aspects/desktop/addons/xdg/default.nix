{den, ...}: let
  cacheDir = ".local/cache";
in {
  den.aspects.desktop.addons.xdg = {
    vmSmoke = [
      {
        name = "desktop-portal";
        description = "The desktop portal owns its session bus name";
        phase = "session";
        script = ''
          assert login_user is not None, "desktop portal smoke test requires vmSmoke.loginUser"
          machine.wait_until_succeeds(user_command("systemctl --user is-active --quiet xdg-desktop-portal.service"))
          machine.succeed(user_command("busctl --user status org.freedesktop.portal.Desktop"))
        '';
      }
    ];

    # uwsm builds the graphical session from /etc/profile, so core.nix's
    # default would otherwise reach GUI apps and the user manager.
    nixos = {lib, ...}: {
      environment.sessionVariables.XDG_CACHE_HOME = lib.mkForce "$HOME/${cacheDir}";
    };

    homeManager = {
      config,
      lib,
      ...
    }: {
      home.sessionVariables = {
        HISTFILE = lib.mkForce "${config.xdg.stateHome}/bash/history";
        GTK2_RC_FILES = lib.mkForce "${config.xdg.configHome}/gtk-2.0/gtkrc";
      };

      xdg = {
        enable = true;
        cacheHome = "${config.home.homeDirectory}/${cacheDir}";
        userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
          extraConfig.SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };
  };
}
