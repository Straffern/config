{
  den,
  inputs,
  ...
}: {
  den.aspects.services.dankgreeter = {
    vmSmoke = [
      {
        name = "dank-greeter";
        description = "Dank Greeter remains alive";
        phase = "greeter";
        script = ''
          machine.wait_for_unit("greetd.service")
          machine.wait_until_succeeds("pgrep -x dms-greeter")
          machine.sleep(5)
          machine.succeed("systemctl is-active --quiet greetd.service")
          machine.succeed("pgrep -x dms-greeter")
        '';
      }
      {
        name = "graphical-login";
        description = "greetd authenticates the VM test user";
        phase = "login";
        script = ''
          assert login_user is not None, "Dank Greeter smoke test requires vmSmoke.loginUser"
          machine.succeed("systemctl start vm-smoke-login.service")
          machine.sleep(1)
          machine.send_chars(login_user)
          machine.send_key("ret")
          machine.sleep(1)
          machine.send_chars("test")
          machine.send_key("ret")
          machine.wait_until_succeeds(f"pgrep -u {login_uid} -x niri", timeout=120)
          machine.wait_until_succeeds(f"loginctl show-user {login_user} -p State --value | grep -Fx active", timeout=30)
        '';
      }
    ];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.dank-greeter.nixosModules.default];
      programs.dms-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = config.users.users.alex.home;
      };
      users.users.greeter.home = "/var/lib/dms-greeter";
      services.fprintd.enable = true;
      security.pam.services.login.fprintAuth = false;
      security.pam.services = {
        greetd = {
          fprintAuth = true;
          rules.auth.fprintd.settings = {
            "max-tries" = "1";
            timeout = "5";
          };
        };
        dms-greeter = {
          fprintAuth = true;
          rules.auth.fprintd.settings = {
            "max-tries" = "1";
            timeout = "5";
          };
        };
      };
      environment.systemPackages = [pkgs.fprintd];
      systemd.services.greetd.serviceConfig = {
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };
      systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
      systemd.user.extraConfig = "DefaultTimeoutStopSec=10s\n";
    };
  };
}
