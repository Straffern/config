# Rex (Superlogical) login server: one root service that maps the caller's Tailscale
# identity to the account and hands off to that account's server. Account servers
# outlive login-server restarts and upgrades, so running programs survive deploys.
# Clients (iOS app, `rex -S`) connect to https://<host>.<tailnet>.ts.net through the
# host's own Tailscale Serve on port 7297; local and ssh:// use reach the same server.
# Lingering keeps the account server alive without a login session.
{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.rex = {
    url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.services.rex = {user}: {
    includes = [den.aspects.services.tailscale];
    nixos = {
      imports = [inputs.rex.nixosModules.default];
      services.rex.loginServer = {
        enable = true;
        accounts.${user.userName}.principals = ["tailscale:Straffern@github"];
        tailscaleServe.enable = true;
      };
      users.users.${user.userName}.linger = true;
    };
  };
}
