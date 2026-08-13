{den, ...}: {
  den.aspects.development.state.homeManager = _: {
    home.persistence."/persist".directories = [
      ".cargo"
      ".config/github-copilot"
      ".local/share/livebook"
    ];
  };
}
