{
  den,
  inputs,
  ...
}: {
  # No nixpkgs follows: Noctalia's cachix holds builds against the flake's own nixpkgs.
  flake-file.inputs.noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";

  den.aspects.services.noctalia-greeter = {
    vmSmoke = [
      {
        name = "noctalia-greeter";
        description = "Noctalia Greeter remains alive";
        phase = "greeter";
        script = ''
          machine.wait_for_unit("greetd.service")
          # The compositor exits if its VT loses the seat before startup completes, so wait for the first frame.
          machine.wait_until_succeeds("journalctl -b -q -t noctalia-greeter --grep 'greeter initialized'", timeout=120)
          machine.sleep(5)
          machine.succeed("systemctl is-active --quiet greetd.service")
          machine.succeed("pgrep -f noctalia-greeter-compositor")
        '';
      }
    ];

    nixos = {
      host,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.noctalia-greeter.nixosModules.default];
      services.displayManager.noctalia-greeter = {
        enable = true;
        # Settings → Security → Noctalia Greeter → Sync copies the shell's look without a password prompt.
        passwordless-sync-users = builtins.attrNames host.users;
        cursorTheme.package = pkgs.phinger-cursors;
        settings = {
          session.default = lib.mkIf (host.hasAspect den.aspects.desktop.hyprland) "Hyprland";
          cursor = {
            theme = "phinger-cursors-dark";
            size = 24;
          };
          keyboard = {
            layout = "us,dk";
            options = "grp:alts_toggle";
          };
          # An empty submit starts pam_fprintd.
          auth.allow_empty_password = true;
        };
      };
      services.fprintd.enable = true;
      # Noctalia's lock screen drives the reader itself over D-Bus.
      security.pam.services.login.fprintAuth = false;
      security.pam.services.greetd = {
        fprintAuth = true;
        rules.auth.fprintd.settings = {
          "max-tries" = "2";
          timeout = "10";
        };
      };
    };
  };
}
