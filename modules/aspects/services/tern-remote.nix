# Headless Tern host: `tern remote serve --user` from a mutable install in
# ~/.local/share/tern (closed beta, self-managed binary). Reachable on the
# tailnet only; clients authenticate with the user's SSH keys.
{den, ...}: {
  den.aspects.services.tern-remote = {user}: {
    includes = [den.aspects.services.tailscale den.aspects.platform.nix-ld];
    nixos = {pkgs, ...}: {
      programs.nix-ld.libraries = [pkgs.linux-pam];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [8376];
      users.users.${user.userName}.linger = true;
    };
    homeManager = {
      systemd.user.services.tern-remote = {
        Unit = {
          Description = "Tern remote serve";
          ConditionPathExists = "%h/.local/share/tern/tern";
        };
        Service = {
          ExecStart = "%h/.local/share/tern/tern remote serve --user --authorized-keys /etc/ssh/authorized_keys.d/${user.userName}";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
