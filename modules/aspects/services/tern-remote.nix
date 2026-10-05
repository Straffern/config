# Headless Tern host: `tern remote serve --user` from a mutable install in
# ~/.local/share/tern (closed beta, self-managed binary). Reachable on the
# tailnet only; clients authenticate with the user's SSH keys. Web panes need
# WebKitGTK 4.1 (nixpkgs has no WPE WebKit), which needs a display: Xvfb.
{den, ...}: {
  den.aspects.services.tern-remote = {user}: {
    includes = [den.aspects.services.tailscale den.aspects.platform.nix-ld];
    nixos = {pkgs, ...}: {
      programs.nix-ld.libraries = [pkgs.linux-pam pkgs.webkitgtk_4_1];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [8376];
      users.users.${user.userName}.linger = true;
    };
    homeManager = {pkgs, ...}: {
      systemd.user.services.tern-xvfb = {
        Unit.Description = "Virtual X display for Tern web panes";
        Service = {
          ExecStart = "${pkgs.xvfb}/bin/Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp";
          Restart = "on-failure";
        };
      };
      systemd.user.services.tern-remote = {
        Unit = {
          Description = "Tern remote serve";
          ConditionPathExists = "%h/.local/share/tern/tern";
          Requires = ["tern-xvfb.service"];
          After = ["tern-xvfb.service"];
        };
        Service = {
          ExecStart = "%h/.local/share/tern/tern remote serve --user --authorized-keys /etc/ssh/authorized_keys.d/${user.userName}";
          Environment = ["DISPLAY=:99"];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
