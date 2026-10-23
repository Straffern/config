usage() {
  cat <<'EOF'
Usage: romm-add [-p PLATFORM] PATH...

Upload ROMs into RomM's library on palantir; RomM rescans on file changes and
fetches metadata itself.

Without -p, igir sorts each file into its RomM platform folder by extension.
Files it can't place (archives, .iso, .cue/.bin, .chd, ...) stop the run
before anything uploads: send them with -p and a RomM platform slug (psx,
ps2, ngc, wii, saturn, ...), e.g.
  romm-add -p psx "Final Fantasy VII (USA)/"

Environment: ROMM_LIBRARY overrides the rsync destination
(default palantir:/var/lib/romm/library/roms).
EOF
}

dest=${ROMM_LIBRARY:-palantir:/var/lib/romm/library/roms}
platform=
while getopts p:h opt; do
  case $opt in
    p) platform=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { usage >&2; exit 2; }
for path in "$@"; do
  [ -e "$path" ] || { echo "romm-add: no such file: $path" >&2; exit 1; }
done

if [ -n "$platform" ]; then
  exec rsync -rL --mkpath --info=progress2 "$@" "$dest/$platform/"
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
# Symlinked inputs keep igir from reading glob syntax such as "[!]" in ROM names.
mkdir "$stage/in" "$stage/out"
for path in "$@"; do ln -s "$(realpath "$path")" "$stage/in/"; done

if ! igir link --link-mode symlink --disable-cache \
  -i "$stage/in/" -o "$stage/out/{romm}/" >"$stage/igir.log" 2>&1; then
  cat "$stage/igir.log" >&2
  exit 1
fi

placed=$(find "$stage/out" -type l -exec realpath {} + | sort -u)
unplaced=$(find -L "$stage/in" -type f -exec realpath {} + | sort -u | comm -23 - <(printf '%s\n' "$placed") | sed 's/^/  /')
if [ -n "$unplaced" ]; then
  echo "romm-add: no platform for these files; upload them with -p PLATFORM:" >&2
  echo "$unplaced" >&2
  exit 1
fi

(cd "$stage/out" && find . -type l | sed 's|^\./||' | sort)
rsync -rL --info=progress2 "$stage/out/" "$dest/"
