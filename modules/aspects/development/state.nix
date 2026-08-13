{den, ...}: {
  den.aspects.development.state.homeManager = {
    host,
    lib,
    ...
  }:
    lib.mkIf (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [
        ".cargo"
        ".config/github-copilot"
        ".local/share/livebook"
      ];
    };
}
