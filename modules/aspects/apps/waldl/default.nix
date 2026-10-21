{
  den,
  inputs,
  ...
}: let
  waldl = pkgs: pkgs.callPackage ./_package {};
in {
  den.aspects.apps.waldl = {
    homeManager = {
      config,
      host,
      pkgs,
      ...
    }: let
      homeSecretsFile = inputs.self + "/secrets/homes/${host.name}.yaml";
      toml = (pkgs.formats.toml {}).generate "waldl-config.toml" {
        general.wallpaper_dir = "${config.home.homeDirectory}/Pictures/wallpapers/wallhaven";
        api.key_file = config.sops.secrets.wallhaven_key.path;
      };
    in {
      sops.secrets.wallhaven_key.sopsFile = homeSecretsFile;
      home.packages = [(waldl pkgs)];
      xdg.configFile."waldl/config.toml".source = toml;
    };

    packages = {pkgs, ...}: {
      waldl = waldl pkgs;
    };
  };
}
