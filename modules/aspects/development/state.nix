{den, ...}: {
  den.aspects.development.state.homeManager = {
    lib,
    host,
    ...
  }:
    lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
      home.persistence."/persist".directories = [
        ".cargo"
        ".config/github-copilot"
        ".local/share/livebook"
      ];
    };
}
