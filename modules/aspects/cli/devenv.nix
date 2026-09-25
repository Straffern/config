{ den, ... }: {
  flake-file.inputs.devenv.url = "github:cachix/devenv";
  den.aspects.cli.devenv.homeManager =
    {
      config,
      inputs',
      lib,
      host,
      ...
    }:
    lib.mkMerge [
      {
        home.packages = [ inputs'.devenv.packages.devenv ];
        # Store path: flake devShells shadow `devenv` with a wrapper lacking `hook`.
        programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''eval "$(${lib.getExe inputs'.devenv.packages.devenv} hook zsh)"'';
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [
          ".config/devenv"
          ".local/share/devenv"
        ];
      })
    ];
}
