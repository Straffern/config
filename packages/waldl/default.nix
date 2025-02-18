{ pkgs ? import <nixpkgs> { }, walldir ? "$HOME/.local/share/wallhaven"
, sorting ? "relevance", quality ? "large", atleast ? "1920x1080" }:

pkgs.writeShellScriptBin "waldl" ''
  #!${pkgs.stdenv.shell}
  #
  # Add dependencies to PATH so that the script finds them.
  export PATH=${pkgs.sxiv}/bin:${pkgs.dmenu}/bin:${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH

  version="0.0.1"

  # default viewer; user may override via environment variable
  [ -z "$VIEWER" ] && VIEWER=sxiv
  # directory for wallpapers and thumbnail cache
  # walldir="$HOME/.local/share/wallhaven"
  cachedir="$HOME/.cache/wallhaven"
  # sxiv options: note that the 'o' flag is needed for selection
  sxiv_otps=" -tfpo -z 200"
  # number of pages to show in search results (each page contains 24 results)
  max_pages=4
  # sorting: date_added, relevance, random, views, favorites, toplist
  # sorting=relevance
  # quality: large, original, small
  # quality=large
  # at least this resolution:
  # atleast=1920x1080

  # allow the user to customize defaults
  [ -e "$HOME/.config/waldlrc" ] && . "$HOME/.config/waldlrc"

  # menu command when no query is provided (default uses dmenu)
  sh_menu () {
      : | dmenu -p "search wallhaven:"
      # If you prefer rofi, try instead:
      # rofi -dmenu -l 0 -p "search wallpapers"
  }

  # getting the search query
  [ -n "$*" ] && query="$*" || query=$( sh_menu )
  [ -z "$query" ] && exit 1
  query=$(printf '%s' "$query" | tr ' ' '+' )

  # prepare directories for caching and wallpaper storage
  rm -rf "$cachedir"
  mkdir -p "${walldir}" "$cachedir"

  # function for progress display and notifications
  sh_info () {
      printf "%s\n" "$1" >&2
      notify-send "wallhaven" "$1"
      [ -n "$2" ] && exit "$2"
  }

  # dependency checking: ensure required commands exist
  dep_ck () {
      for pr; do
          command -v $pr >/dev/null 2>&1 || sh_info "command $pr not found, install: $pr" 1
      done
  }
  dep_ck "$VIEWER" "curl" "jq"

  # clean up when the program exits
  clean_up () {
      printf "%s\n" "cleaning up..." >&2
      rm -rf "$datafile" "$cachedir"
  }

  # temporary file for API data
  datafile="/tmp/wald.$$"

  # clean up if the script is interrupted
  trap "exit" INT TERM
  trap "clean_up" EXIT

  # function to retrieve search results from wallhaven API
  get_results () {
      for page_no in $(seq $max_pages)
      do
          {
              json=$(curl -s -G "https://wallhaven.cc/api/v1/search" \
                      -d "q=$1" \
                      -d "page=$page_no" \
                      -d "atleast=${atleast}" \
                      -d "sorting=${sorting}"
                  )
              printf "%s\n" "$json" >> "$datafile"
          } &
          sleep 0.001
      done
      wait
  }

  sh_info "getting data..."
  get_results "$query"

  # exit if no data was retrieved
  [ -s "$datafile" ] || sh_info "no images found" 1 

  # extract list of thumbnail URLs from JSON data
  thumbnails=$( jq -r '.data[]?|.thumbs.'"${quality}" < "$datafile")

  [ -z "$thumbnails" ] && sh_info "no-results found" 1

  sh_info "caching thumbnails..."
  for url in $thumbnails
  do
      printf "url = %s\n" "$url"
      printf "output = %s\n" "$cachedir/''${url##*/}"
  done | curl -Z -K -

  # open thumbnails in viewer (sxiv) for selection
  image_ids="$($VIEWER $sxiv_otps "$cachedir")"
  [ -z "$image_ids" ] && exit

  # download selected wallpapers into walldir
  cd "$walldir"
  sh_info "downloading wallpapers..."
  for ids in $image_ids
  do
      ids="''${ids##*/}"
      ids="''${ids%.*}"
      url=$( jq -r '.data[]?|select( .id == "'$ids'" )|.path' < "$datafile" )
      printf "url = %s\n" "$url"
      printf -- "-O\n"
  done | curl -K -

  sh_info "wallpapers downloaded in:- '${walldir}'"
  $VIEWER $(ls -c)
''
