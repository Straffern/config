{ den, ... }: {
  flake-file.inputs.devenv.url = "github:cachix/devenv";
  den.aspects.cli.devenv.homeManager =
    {
      config,
      inputs',
      lib,
      host,
      pkgs,
      ...
    }: let
      devenv = inputs'.devenv.packages.devenv;
      zshHook = pkgs.runCommand "devenv-zsh-hook" {} ''
        ${lib.getExe devenv} hook zsh > "$out"
      '';
    in
    lib.mkMerge [
      {
        home.packages = [ devenv ];
        # Generate with the real package; devShell wrappers do not provide `hook`.
        programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''source ${zshHook}'';
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [
          ".config/devenv"
          ".local/share/devenv"
        ];
      })
    ];
}
