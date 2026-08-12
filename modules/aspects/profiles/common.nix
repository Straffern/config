{den, ...}: {
  den.aspects.profiles.common = {
    includes = [
      den.aspects.apps.brave
      den.aspects.apps.helium
      den.aspects.cli.kitty
      den.aspects.cli.zsh
      den.aspects.platform.zsh
      den.aspects.services.openssh
      den.aspects.network.networkmanager
      den.aspects.platform.locale
      den.aspects.platform.nix
      den.aspects.storage.impermanence-modules
      den.aspects.security.sops
      den.aspects.styles.fonts
      den.aspects.styles.stylix
    ];
    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      home = {
        packages = with pkgs; [
          keymapp
          src-cli
          (lib.hiPrio parallel)
          moreutils
          nvtopPackages.amd
          unzip
          showmethekey
        ];
        persistence."/persist".directories = [
          ".cargo"
          ".config/github-copilot"
          ".config/Slack"
          ".config/blender"
          ".local/share/livebook"
        ];
      };
    };
  };
}
