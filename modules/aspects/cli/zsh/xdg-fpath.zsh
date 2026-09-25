# Completions for tools from direnv/nix dev shells: zsh reads fpath, not XDG_DATA_DIRS.
typeset -g _xdg_fpath_seen
_xdg_fpath_sync() {
  [[ $XDG_DATA_DIRS == "$_xdg_fpath_seen" ]] && return
  _xdg_fpath_seen=$XDG_DATA_DIRS
  local d f line
  for d in ${(s.:.)XDG_DATA_DIRS}; do
    d=$d/zsh/site-functions
    [[ -d $d && -z ${fpath[(r)$d]} ]] || continue
    fpath=($d $fpath)
    for f in $d/_*(N.); do
      read -r line < $f
      [[ $line == '#compdef '* ]] || continue
      autoload -Uz ${f:t}
      compdef ${f:t} ${=line#\#compdef }
    done
  done
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _xdg_fpath_sync
