{
  den,
  inputs,
  ...
}: {
  den.aspects.desktop.hyprland = {
    includes = [den.aspects.development.mutable-source];
    vmSmoke = [
      {
        name = "hyprland-session";
        description = "The greeter sees one Hyprland session and UWSM accepts its command";
        script = ''
          assert login_user is not None, "Hyprland session smoke test requires vmSmoke.loginUser"
          data_dirs = machine.succeed("sed -n 's/^XDG_DATA_DIRS[[:space:]]*DEFAULT=\"\\(.*\\)\"$/\\1/p' /etc/pam/environment").strip().split(":")
          globs = " ".join(f"{d}/wayland-sessions/*.desktop" for d in data_dirs if d.startswith("/"))
          names = set(machine.succeed(f"grep -h '^Name=.*Hyprland' {globs} 2>/dev/null || true").splitlines())
          assert names == {"Name=Hyprland"}, f"greeter-visible Hyprland sessions: {names}"
          command = machine.succeed(f"grep -h -m1 '^Exec=' $(grep -l '^Name=Hyprland$' {globs} 2>/dev/null) | head -n1").strip().removeprefix("Exec=")
          machine.succeed(user_command(command.replace(" start ", " start -n ", 1)))
        '';
      }
    ];
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      unstable = inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      cfg = config.programs.hyprland;
      session = pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
        [Desktop Entry]
        Name=Hyprland
        Exec=${lib.getExe config.programs.uwsm.package} start -e -D Hyprland -N Hyprland -- ${cfg.package}/bin/start-hyprland
        DesktopNames=Hyprland
        Type=Application
      '';
      sessionPackages = [session] ++ builtins.filter (p: p.outPath != cfg.package.outPath) config.services.displayManager.sessionPackages;
    in {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = unstable.hyprland;
        portalPackage = unstable.xdg-desktop-portal-hyprland;
      };
      # nixpkgs Hyprland ships a plain and a UWSM session entry and both greeters list every entry on XDG_DATA_DIRS,
      # so both session directories get the single entry above instead. sessionData merges with //, so order it last.
      services.displayManager.sessionData = lib.mkAfter {
        desktops = pkgs.runCommand "desktops" {} ''
          mkdir -p $out/share/{xsessions,wayland-sessions}
          ${lib.concatMapStrings (p: ''
              for d in xsessions wayland-sessions; do
                if [ -d ${p}/share/$d ]; then ${lib.getExe' pkgs.buildPackages.lndir "lndir"} -silent ${p}/share/$d $out/share/$d; fi
              done
            '')
            sessionPackages}
        '';
      };
      environment.extraSetup = ''
        rm $out/share/wayland-sessions/hyprland.desktop $out/share/wayland-sessions/hyprland-uwsm.desktop
      '';
      assertions = [
        {
          assertion =
            cfg.package.outPath
            == unstable.hyprland.outPath
            && cfg.portalPackage.outPath == unstable.xdg-desktop-portal-hyprland.outPath;
          message = "Hyprland must be the unmodified nixpkgs-unstable build so it substitutes from cache.nixos.org.";
        }
      ];
    };
  };
}
