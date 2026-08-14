{den, ...}: {
  flake-file.inputs.nixgl = {
    url = "github:nix-community/nixGL";
    inputs.nixpkgs.follows = "nixpkgs";
  };

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
    };
    nix-ld.nixos = {pkgs, ...}: {
      programs.nix-ld = {
        enable = true;
        libraries = [pkgs.zlib];
      };
    };
  };
}
