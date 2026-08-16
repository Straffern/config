{den, ...}: {
  den.aspects.platform = {
    nh = {user}: {
      nixos = {config, ...}: {
        programs.nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
          flake = "${config.users.users.${user.userName}.home}/.dotfiles";
        };
      };
      homeManager = {config, ...}: {
        home.sessionVariables.NH_FLAKE = "${config.home.homeDirectory}/.dotfiles";
      };
    };
    nix-ld.nixos = {pkgs, ...}: {
      programs.nix-ld = {
        enable = true;
        libraries = [pkgs.zlib];
      };
    };
  };
}
