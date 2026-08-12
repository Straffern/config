{den, ...}: let
  waldl = pkgs: pkgs.callPackage ./_waldl {};
in {
  den.aspects.apps.waldl = {
    homeManager = {
      config,
      pkgs,
      ...
    }: let
      toml = (pkgs.formats.toml {}).generate "waldl-config.toml" {
        general.wallpaper_dir = "${config.home.homeDirectory}/.dotfiles/modules/aspects/styles/_wallpapers/wallpapers";
        api.key_file = config.sops.secrets.wallhaven_key.path;
      };
    in {
      sops.secrets.wallhaven_key.sopsFile = ../../../secrets/hosts/sonic.yaml;
      home.packages = [(waldl pkgs)];
      xdg.configFile."waldl/config.toml".source = toml;
    };

    packages = {pkgs, ...}: {
      waldl = waldl pkgs;
    };
  };
}
