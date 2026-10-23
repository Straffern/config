# Seed .envrc from .envrc.example on entering a directory that has none.
_envrc_example_seed() {
  [[ -f .envrc.example && ! -e .envrc ]] && cp .envrc.example .envrc
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _envrc_example_seed
_envrc_example_seed
