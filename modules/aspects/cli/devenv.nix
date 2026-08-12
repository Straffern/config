{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.devenv.url = "github:cachix/devenv";
  den.aspects.cli.devenv.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = [inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv];
    programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''eval "$(devenv hook zsh)"'';
    home.persistence."/persist".directories = [
      ".config/devenv"
      ".local/share/devenv"
    ];
  };
}
