#!/usr/bin/env bash

# waldl - Wallhaven Downloader
# Improved version for Asgaard Dotfiles

set -e

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

CACHEDIR="$XDG_CACHE_HOME/waldl"
WALLDIR="$XDG_DATA_HOME/wallpapers/wallhaven"
APPLIED_WALLDIR="$XDG_DATA_HOME/waldl/wallpapers"
CONFIG_FILE="$XDG_CONFIG_HOME/waldl/config"

QUERY=""
SORTING="date_added"
PURITY="100"
CATEGORIES="111"
VIEWER="nsxiv"
API_KEY=""

# Resolution filter settings
ATLEAST_ENABLED="true"
ATLEAST_VALUE="auto"  # "auto" = detect from monitor, or specific like "1920x1080"
EXACT_ENABLED="false"
EXACT_VALUE=""  # Comma-separated: "1920x1080,2560x1440"

# Toplist time range (only used when SORTING=toplist)
TOPLIST_RANGE="1M"  # 1d, 3d, 1w, 1M, 3M, 6M, 1y

# --- Resolution Presets ---
# Format: "AspectRatio:res1,res2,res3,..."
declare -A RESOLUTION_PRESETS=(
    ["Ultrawide"]="2560x1080,3440x1440,3840x1600"
    ["16:9"]="1280x720,1600x900,1920x1080,2560x1440,3840x2160"
    ["16:10"]="1280x800,1600x1000,1920x1200,2560x1600,3840x2400"
    ["4:3"]="1280x960,1600x1200,1920x1440,2560x1920,3840x2880"
    ["5:4"]="1280x1024,1600x1280,1920x1536,2560x2048,3840x3072"
)
ASPECT_RATIO_ORDER=("Ultrawide" "16:9" "16:10" "4:3" "5:4")

# --- Toplist Range Options ---
declare -A TOPLIST_RANGES=(
    ["Last Day"]="1d"
    ["Last Three Days"]="3d"
    ["Last Week"]="1w"
    ["Last Month"]="1M"
    ["Last 3 Months"]="3M"
    ["Last 6 Months"]="6M"
    ["Last Year"]="1y"
)
TOPLIST_ORDER=("Last Day" "Last Three Days" "Last Week" "Last Month" "Last 3 Months" "Last 6 Months" "Last Year")

SETTINGS_FILE="$XDG_CONFIG_HOME/waldl/settings"

load_settings() {
    # shellcheck source=/dev/null
    [[ -f "$SETTINGS_FILE" ]] && source "$SETTINGS_FILE" || true
}

save_settings() {
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    cat > "$SETTINGS_FILE" <<EOF
SORTING="$SORTING"
PURITY="$PURITY"
CATEGORIES="$CATEGORIES"
ATLEAST_ENABLED="$ATLEAST_ENABLED"
ATLEAST_VALUE="$ATLEAST_VALUE"
EXACT_ENABLED="$EXACT_ENABLED"
EXACT_VALUE="$EXACT_VALUE"
TOPLIST_RANGE="$TOPLIST_RANGE"
EOF
}

get_monitor_resolution() {
    local mon_info fallback="1920x1080"
    mon_info=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | "\(.width)x\(.height)"')
    if [[ -n "$mon_info" ]]; then
        echo "$mon_info"
    else
        echo "$fallback"
    fi
}

get_viewer_geometry() {
    local mon_info fallback="1600x900"
    mon_info=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | "\(.width) \(.height)"')
    if [[ -n "$mon_info" ]]; then
        read -r mon_w mon_h <<< "$mon_info"
        # Dynamic window percentage based on resolution:
        # - 4K (3840+): 70% window
        # - 1440p (2560+): 65% window  
        # - 1080p and below: 60% window
        local pct=60
        if (( mon_w >= 3840 )); then
            pct=70
        elif (( mon_w >= 2560 )); then
            pct=65
        fi
        echo "$((mon_w * pct / 100))x$((mon_h * pct / 100))"
    else
        echo "$fallback"
    fi
}

resolve_atleast() {
    if [[ "$ATLEAST_ENABLED" != "true" ]]; then
        echo ""
        return
    fi
    if [[ "$ATLEAST_VALUE" == "auto" ]]; then
        get_monitor_resolution
    else
        echo "$ATLEAST_VALUE"
    fi
}

VIEWER_GEOMETRY=$(get_viewer_geometry)
VIEWER_OPTS=(-tfpo -z 500 -g "$VIEWER_GEOMETRY")

# Pagination state
CURRENT_PAGE=1
TOTAL_PAGES=1
LAST_PAGE=1


if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

load_settings

# Override with environment variables if present
SORTING="${WALDL_SORTING:-$SORTING}"
PURITY="${WALDL_PURITY:-$PURITY}"
CATEGORIES="${WALDL_CATEGORIES:-$CATEGORIES}"
API_KEY="${WALDL_API_KEY:-$API_KEY}"
WALLDIR="${WALDL_WALLDIR:-$WALLDIR}"

if [[ -n "${WALDL_ATLEAST:-}" ]]; then
    ATLEAST_ENABLED="true"
    ATLEAST_VALUE="$WALDL_ATLEAST"
fi
ATLEAST=$(resolve_atleast)

# --- Rofi Keybindings ---
# Space=select, Enter=done/search, q=quit, /=query shortcut
ROFI_MENU_KEYS=(-kb-accept-entry "space,Return" -kb-cancel "q,Escape" -kb-custom-1 "slash")
ROFI_TOGGLE_KEYS=(-kb-accept-entry "space" -kb-cancel "Escape" -kb-custom-1 "Return")
ROFI_INPUT_KEYS=(-kb-accept-entry "Return" -kb-cancel "q,Escape")
ROFI_SELECT_KEYS=(-kb-accept-entry "space,Return" -kb-cancel "q,Escape")

# --- Setup Directories ---
mkdir -p "$CACHEDIR/thumbnails" "$CACHEDIR/api_cache" "$WALLDIR"

# --- Helper Functions ---
msg() {
    echo "=> $*"
}

notify() {
    if command -v notify-send >/dev/null; then
        notify-send "waldl" "$1"
    fi
}

get_search_hash() {
    local exact_part=""
    [[ "$EXACT_ENABLED" == "true" ]] && exact_part="$EXACT_VALUE"
    local toplist_part=""
    [[ "$SORTING" == "toplist" ]] && toplist_part="$TOPLIST_RANGE"
    echo -n "${QUERY}|${SORTING}|${PURITY}|${CATEGORIES}|${ATLEAST}|${exact_part}|${toplist_part}|${API_KEY}" | md5sum | cut -d' ' -f1
}

manage_purity() {
    while true; do
        sfw=$([[ ${PURITY:0:1} == 1 ]] && echo "[x]" || echo "[ ]")
        sk=$([[ ${PURITY:1:1} == 1 ]] && echo "[x]" || echo "[ ]")
        nsfw=$([[ ${PURITY:2:1} == 1 ]] && echo "[x]" || echo "[ ]")

        rofi_exit=0
        opt=$(printf "%s SFW\n%s Sketchy\n%s NSFW" "$sfw" "$sk" "$nsfw" | rofi -dmenu -p "Purity [Enter=done]" -i "${ROFI_TOGGLE_KEYS[@]}") || rofi_exit=$?
        
        [[ $rofi_exit == 10 || $rofi_exit == 1 ]] && return
        
        case "$opt" in
        *" NSFW") PURITY="${PURITY:0:2}$((1 - ${PURITY:2:1}))" ;;
        *" SFW") PURITY="$((1 - ${PURITY:0:1}))${PURITY:1:2}" ;;
        *" Sketchy") PURITY="${PURITY:0:1}$((1 - ${PURITY:1:1}))${PURITY:2:1}" ;;
        *) return ;;
        esac
    done
}

manage_categories() {
    while true; do
        gen=$([[ ${CATEGORIES:0:1} == 1 ]] && echo "[x]" || echo "[ ]")
        ani=$([[ ${CATEGORIES:1:1} == 1 ]] && echo "[x]" || echo "[ ]")
        peo=$([[ ${CATEGORIES:2:1} == 1 ]] && echo "[x]" || echo "[ ]")

        rofi_exit=0
        opt=$(printf "%s General\n%s Anime\n%s People" "$gen" "$ani" "$peo" | rofi -dmenu -p "Categories [Enter=done]" -i "${ROFI_TOGGLE_KEYS[@]}") || rofi_exit=$?
        
        [[ $rofi_exit == 10 || $rofi_exit == 1 ]] && return
        
        case "$opt" in
        *" General") CATEGORIES="$((1 - ${CATEGORIES:0:1}))${CATEGORIES:1:2}" ;;
        *" Anime") CATEGORIES="${CATEGORIES:0:1}$((1 - ${CATEGORIES:1:1}))${CATEGORIES:2:1}" ;;
        *" People") CATEGORIES="${CATEGORIES:0:2}$((1 - ${CATEGORIES:2:1}))" ;;
        *) return ;;
        esac
    done
}

get_toplist_display() {
    local api_val="$1"
    for display in "${TOPLIST_ORDER[@]}"; do
        if [[ "${TOPLIST_RANGES[$display]}" == "$api_val" ]]; then
            echo "$display"
            return
        fi
    done
    echo "Last Month"
}

manage_toplist_range() {
    local menu_items=""
    for display in "${TOPLIST_ORDER[@]}"; do
        menu_items+="$display\n"
    done
    
    rofi_exit=0
    selection=$(printf "%b" "$menu_items" | rofi -dmenu -p "Toplist Range" "${ROFI_SELECT_KEYS[@]}") || rofi_exit=$?
    
    if [[ $rofi_exit == 0 && -n "$selection" ]]; then
        TOPLIST_RANGE="${TOPLIST_RANGES[$selection]}"
        save_settings
    fi
}

pick_resolution_from_aspect() {
    local aspect="$1"
    local allow_multi="$2"
    local current_selections="$3"
    
    IFS=',' read -ra resolutions <<< "${RESOLUTION_PRESETS[$aspect]}"
    
    if [[ "$allow_multi" == "true" ]]; then
        declare -A selected_map
        IFS=',' read -ra current_arr <<< "$current_selections"
        for r in "${current_arr[@]}"; do
            selected_map["$r"]=1
        done
        
        while true; do
            local menu_items=""
            for res in "${resolutions[@]}"; do
                if [[ -n "${selected_map[$res]:-}" ]]; then
                    menu_items+="[x] $res\n"
                else
                    menu_items+="[ ] $res\n"
                fi
            done
            
            rofi_exit=0
            selection=$(printf "%b" "$menu_items" | rofi -dmenu -p "$aspect [Enter=done]" -i "${ROFI_TOGGLE_KEYS[@]}") || rofi_exit=$?
            
            [[ $rofi_exit == 10 || $rofi_exit == 1 ]] && break
            
            local res="${selection#*] }"
            if [[ -n "${selected_map[$res]:-}" ]]; then
                unset "selected_map[$res]"
            else
                selected_map["$res"]=1
            fi
        done
        
        local result=""
        for r in "${!selected_map[@]}"; do
            [[ -n "$result" ]] && result+=","
            result+="$r"
        done
        echo "$result"
    else
        rofi_exit=0
        selection=$(printf "%s\n" "${resolutions[@]}" | rofi -dmenu -p "$aspect" "${ROFI_SELECT_KEYS[@]}") || rofi_exit=$?
        
        if [[ $rofi_exit == 0 && -n "$selection" ]]; then
            echo "$selection"
        fi
    fi
}

manage_atleast() {
    local current_display
    if [[ "$ATLEAST_ENABLED" != "true" ]]; then
        current_display="OFF"
    elif [[ "$ATLEAST_VALUE" == "auto" ]]; then
        current_display="Auto ($(get_monitor_resolution))"
    else
        current_display="$ATLEAST_VALUE"
    fi
    
    local menu_items="Toggle: $current_display\n---\nAuto-detect\n"
    for aspect in "${ASPECT_RATIO_ORDER[@]}"; do
        menu_items+="$aspect\n"
    done
    menu_items+="Custom..."
    
    rofi_exit=0
    selection=$(printf "%b" "$menu_items" | rofi -dmenu -p "Atleast Resolution" "${ROFI_SELECT_KEYS[@]}") || rofi_exit=$?
    
    [[ $rofi_exit != 0 ]] && return
    
    case "$selection" in
        "Toggle: "*)
            if [[ "$ATLEAST_ENABLED" == "true" ]]; then
                ATLEAST_ENABLED="false"
                EXACT_ENABLED="false"
            else
                ATLEAST_ENABLED="true"
                EXACT_ENABLED="false"
            fi
            ;;
        "Auto-detect")
            ATLEAST_ENABLED="true"
            ATLEAST_VALUE="auto"
            EXACT_ENABLED="false"
            ;;
        "Custom...")
            local custom
            custom=$(echo "" | rofi -dmenu -p "Resolution (e.g. 1920x1080)" "${ROFI_INPUT_KEYS[@]}") || true
            if [[ "$custom" =~ ^[0-9]+x[0-9]+$ ]]; then
                ATLEAST_ENABLED="true"
                ATLEAST_VALUE="$custom"
                EXACT_ENABLED="false"
            fi
            ;;
        "---") return ;;
        *)
            for aspect in "${ASPECT_RATIO_ORDER[@]}"; do
                if [[ "$selection" == "$aspect" ]]; then
                    local picked
                    picked=$(pick_resolution_from_aspect "$aspect" "false" "")
                    if [[ -n "$picked" ]]; then
                        ATLEAST_ENABLED="true"
                        ATLEAST_VALUE="$picked"
                        EXACT_ENABLED="false"
                    fi
                    break
                fi
            done
            ;;
    esac
    
    ATLEAST=$(resolve_atleast)
    save_settings
}

manage_exact() {
    local current_display
    if [[ "$EXACT_ENABLED" != "true" ]]; then
        current_display="OFF"
    else
        current_display="${EXACT_VALUE:-none}"
    fi
    
    local menu_items="Toggle: $current_display\n---\n"
    for aspect in "${ASPECT_RATIO_ORDER[@]}"; do
        menu_items+="$aspect\n"
    done
    menu_items+="Custom..."
    
    rofi_exit=0
    selection=$(printf "%b" "$menu_items" | rofi -dmenu -p "Exact Resolution" "${ROFI_SELECT_KEYS[@]}") || rofi_exit=$?
    
    [[ $rofi_exit != 0 ]] && return
    
    case "$selection" in
        "Toggle: "*)
            if [[ "$EXACT_ENABLED" == "true" ]]; then
                EXACT_ENABLED="false"
            else
                EXACT_ENABLED="true"
                ATLEAST_ENABLED="false"
            fi
            ;;
        "Custom...")
            local custom
            custom=$(echo "$EXACT_VALUE" | rofi -dmenu -p "Resolutions (comma-sep)" "${ROFI_INPUT_KEYS[@]}") || true
            if [[ -n "$custom" ]]; then
                EXACT_ENABLED="true"
                EXACT_VALUE="$custom"
                ATLEAST_ENABLED="false"
            fi
            ;;
        "---") return ;;
        *)
            for aspect in "${ASPECT_RATIO_ORDER[@]}"; do
                if [[ "$selection" == "$aspect" ]]; then
                    local picked
                    picked=$(pick_resolution_from_aspect "$aspect" "true" "$EXACT_VALUE")
                    if [[ -n "$picked" ]]; then
                        EXACT_ENABLED="true"
                        EXACT_VALUE="$picked"
                        ATLEAST_ENABLED="false"
                    fi
                    break
                fi
            done
            ;;
    esac
    
    ATLEAST=$(resolve_atleast)
    save_settings
}

# Fetch a single page, using cache if available
# Sets TOTAL_PAGES and LAST_PAGE from API meta
fetch_page() {
    local page=$1
    local search_hash
    search_hash=$(get_search_hash)
    local cache_dir="$CACHEDIR/api_cache/$search_hash"
    local cache_file="$cache_dir/page_${page}.json"
    local meta_file="$cache_dir/meta.json"

    mkdir -p "$cache_dir"

    # Check cache (valid for 1 hour)
    if [[ -f "$cache_file" ]]; then
        local cache_age
        cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
        if (( cache_age < 3600 )); then
            msg "Using cached results for page $page"
            # Load meta if exists
            if [[ -f "$meta_file" ]]; then
                TOTAL_PAGES=$(jq -r '.last_page // 1' "$meta_file")
                LAST_PAGE=$TOTAL_PAGES
            fi
            return 0
        fi
    fi

    msg "Fetching page $page..."
    args=(
        "-s" "-f" "-G" "https://wallhaven.cc/api/v1/search"
        "--data-urlencode" "q=$QUERY"
        "-d" "sorting=$SORTING"
        "-d" "purity=$PURITY"
        "-d" "categories=$CATEGORIES"
        "-d" "page=$page"
    )
    
    if [[ "$EXACT_ENABLED" == "true" && -n "$EXACT_VALUE" ]]; then
        args+=("-d" "resolutions=$EXACT_VALUE")
    elif [[ -n "$ATLEAST" ]]; then
        args+=("-d" "atleast=$ATLEAST")
    fi
    
    if [[ "$SORTING" == "toplist" && -n "$TOPLIST_RANGE" ]]; then
        args+=("-d" "topRange=$TOPLIST_RANGE")
    fi
    
    [[ -n "$API_KEY" ]] && args+=("-d" "apikey=$API_KEY")

    local tmp_json
    tmp_json=$(mktemp)
    if ! curl "${args[@]}" >"$tmp_json" 2>/dev/null; then
        rm -f "$tmp_json"
        return 1
    fi

    if ! jq -e '.data' "$tmp_json" >/dev/null 2>&1; then
        rm -f "$tmp_json"
        return 1
    fi

    # Extract and save pagination meta
    jq '{last_page: .meta.last_page, per_page: .meta.per_page, total: .meta.total}' "$tmp_json" > "$meta_file"
    TOTAL_PAGES=$(jq -r '.meta.last_page // 1' "$tmp_json")
    LAST_PAGE=$TOTAL_PAGES

    # Save to cache
    mv "$tmp_json" "$cache_file"
    return 0
}

# Get the cached page data file path
get_page_cache_file() {
    local page=$1
    local search_hash
    search_hash=$(get_search_hash)
    echo "$CACHEDIR/api_cache/$search_hash/page_${page}.json"
}

download_thumbnails_for_page() {
    local page=$1
    local cache_file
    cache_file=$(get_page_cache_file "$page")

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    local thumbnails
    thumbnails=$(jq -r '.data[]? | "\(.id | tostring) \(.thumbs.large)"' "$cache_file")

    if [[ -z "$thumbnails" ]]; then
        return 0
    fi

    local CURL_CONF
    CURL_CONF=$(mktemp)
    local GLOBAL_CACHE="$CACHEDIR/thumbnails"

    echo "$thumbnails" | while read -r id thumb_url; do
        [[ -z "$id" || -z "$thumb_url" ]] && continue
        ext="${thumb_url##*.}"
        cached_path="$GLOBAL_CACHE/$id.$ext"
        if [[ ! -f "$cached_path" ]]; then
            printf "url = %s\noutput = %s\n" "$thumb_url" "$cached_path" >> "$CURL_CONF"
        fi
    done

    if [[ -s "$CURL_CONF" ]]; then
        msg "Downloading thumbnails for page $page..."
        curl -s -Z -K "$CURL_CONF" || true
    fi
    rm -f "$CURL_CONF"
}

# Build the current view directory with symlinks to thumbnails
build_current_view() {
    local page=$1
    local cache_file
    cache_file=$(get_page_cache_file "$page")
    local THUMBDIR="$CACHEDIR/thumbnails/current"

    rm -rf "$THUMBDIR"
    mkdir -p "$THUMBDIR"

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    local thumbnails
    thumbnails=$(jq -r '.data[]? | "\(.id | tostring) \(.thumbs.large)"' "$cache_file")
    local GLOBAL_CACHE="$CACHEDIR/thumbnails"

    echo "$thumbnails" | while read -r id thumb_url; do
        [[ -z "$id" || -z "$thumb_url" ]] && continue
        ext="${thumb_url##*.}"
        cached_path="$GLOBAL_CACHE/$id.$ext"
        current_path="$THUMBDIR/$id.$ext"
        if [[ -f "$cached_path" ]]; then
            ln -sf "$cached_path" "$current_path"
        fi
    done
}

# Get combined data file for key-handler (current page)
get_current_datafile() {
    get_page_cache_file "$CURRENT_PAGE"
}

search_and_select() {
    local THUMBDIR="$CACHEDIR/thumbnails/current"

    local search_desc="${QUERY:-browse}"
    
    if ! fetch_page "$CURRENT_PAGE"; then
        notify "No images found for '$search_desc' (page $CURRENT_PAGE)"
        return 2
    fi

    download_thumbnails_for_page "$CURRENT_PAGE"
    build_current_view "$CURRENT_PAGE"

    local thumb_count
    thumb_count=$(find "$THUMBDIR" -maxdepth 1 -type l 2>/dev/null | wc -l)
    if [[ "$thumb_count" -eq 0 ]]; then
        notify "No results for '$search_desc'"
        return 2
    fi

    local DATAFILE
    DATAFILE=$(get_current_datafile)

    # --- NSXIV Config ---
    NSXIV_CONF_DIR="$CACHEDIR/nsxiv_conf"
    mkdir -p "$NSXIV_CONF_DIR/nsxiv/exec"
    
    # Capture binary paths at generation time (key-handler runs outside waldl's PATH)
    local BIN_JQ BIN_CURL BIN_IMV BIN_SOCAT BIN_NOTIFY
    BIN_JQ="$(command -v jq)"
    BIN_CURL="$(command -v curl)"
    BIN_IMV="$(command -v imv)"
    BIN_SOCAT="$(command -v socat)"
    BIN_NOTIFY="$(command -v notify-send)"
    
    cat >"$NSXIV_CONF_DIR/nsxiv/exec/key-handler" <<EOF
#!/usr/bin/env bash
key="\$1"
read -r thumb_path

# Binary paths captured from waldl's environment
JQ="$BIN_JQ"
CURL="$BIN_CURL"
IMV="$BIN_IMV"
SOCAT="$BIN_SOCAT"
NOTIFY="$BIN_NOTIFY"

case "\$key" in
    "space")
        id=\$(basename "\$thumb_path" | cut -d. -f1)
        full_url=\$("\$JQ" -r --arg id "\$id" '.data[] | select((.id | tostring) == \$id) | .path' "$DATAFILE")
        
        if [[ -n "\$full_url" && "\$full_url" != "null" ]]; then
            tmp_img="/tmp/waldl_preview_\$id.\${full_url##*.}"
            if [[ ! -s "\$tmp_img" ]]; then
                "\$CURL" -s "\$full_url" -o "\$tmp_img"
            fi
            if [[ -s "\$tmp_img" ]]; then
                "\$IMV" "\$tmp_img" &
            fi
        fi
        ;;
    "p")
        id=\$(basename "\$thumb_path" | cut -d. -f1)
        full_url=\$("\$JQ" -r --arg id "\$id" '.data[] | select((.id | tostring) == \$id) | .path' "$DATAFILE")
        if [[ -n "\$full_url" && "\$full_url" != "null" ]]; then
            img_name="wallhaven-\$id.\${full_url##*.}"
            mkdir -p "$APPLIED_WALLDIR"
            target="$APPLIED_WALLDIR/\$img_name"
            if [[ ! -f "\$target" ]]; then
                "\$CURL" -s "\$full_url" -o "\$target"
            fi
            if [[ -f "\$target" ]]; then
                # Use hyprpaper socket directly via HYPRLAND_INSTANCE_SIGNATURE env var
                HYPRPAPER_SOCK="\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}/hypr/\${HYPRLAND_INSTANCE_SIGNATURE}/.hyprpaper.sock"
                if [[ -S "\$HYPRPAPER_SOCK" ]]; then
                    echo "preload \$target" | "\$SOCAT" - "UNIX-CONNECT:\$HYPRPAPER_SOCK" >/dev/null 2>&1
                    echo "wallpaper ,\$target" | "\$SOCAT" - "UNIX-CONNECT:\$HYPRPAPER_SOCK" >/dev/null 2>&1
                    "\$NOTIFY" "waldl" "Wallpaper set: \$img_name"
                else
                    "\$NOTIFY" "waldl" "hyprpaper socket not found at \$HYPRPAPER_SOCK"
                fi
            fi
        fi
        ;;
esac
EOF
    chmod +x "$NSXIV_CONF_DIR/nsxiv/exec/key-handler"

    # --- Run Viewer ---
    OUTPUT_FILE=$(mktemp)
    set +e
    XDG_CONFIG_HOME="$NSXIV_CONF_DIR" "$VIEWER" "${VIEWER_OPTS[@]}" -o "$THUMBDIR" >"$OUTPUT_FILE"
    RET=$?
    set -e
    SELECTED_THUMBS=$(cat "$OUTPUT_FILE")
    rm -f "$OUTPUT_FILE"

    # Exit codes:
    # 0 = Enter (download selected)
    # 1 = q (quit)
    # 2 = Backspace (back to menu)
    # 3 = Ctrl+d (next page)
    # 4 = Ctrl+u (prev page)

    case $RET in
        0)
            if [[ -n "$SELECTED_THUMBS" ]]; then
                msg "Downloading selected wallpapers..."
                CURL_CONF=$(mktemp)
                for thumb in $SELECTED_THUMBS; do
                    id=$(basename "$thumb" | cut -d. -f1)
                    full_url=$(jq -r --arg id "$id" '.data[] | select((.id | tostring) == $id) | .path' "$DATAFILE")
                    if [[ -n "$full_url" && "$full_url" != "null" ]]; then
                        img_name="wallhaven-$id.${full_url##*.}"
                        [[ ! -f "$WALLDIR/$img_name" ]] && printf "url = %s\noutput = %s\n" "$full_url" "$WALLDIR/$img_name" >> "$CURL_CONF"
                    fi
                done
                if [[ -s "$CURL_CONF" ]]; then
                    curl -Z -K "$CURL_CONF"
                    notify "Download complete: $WALLDIR"
                fi
                rm -f "$CURL_CONF"
            fi
            return 0
            ;;
        2)
            # Back to search menu
            return 2
            ;;
        3)
            # Next page
            if (( CURRENT_PAGE < LAST_PAGE )); then
                CURRENT_PAGE=$((CURRENT_PAGE + 1))
                msg "Going to page $CURRENT_PAGE / $LAST_PAGE"
                return 3
            else
                notify "Already on last page ($LAST_PAGE)"
                return 3
            fi
            ;;
        4)
            # Previous page
            if (( CURRENT_PAGE > 1 )); then
                CURRENT_PAGE=$((CURRENT_PAGE - 1))
                msg "Going to page $CURRENT_PAGE / $LAST_PAGE"
                return 4
            else
                notify "Already on first page"
                return 4
            fi
            ;;
        *)
            # Quit (q or other)
            return 1
            ;;
    esac
}

# --- Main Loop ---
if [[ $# -gt 0 ]]; then QUERY="$*"; fi

edit_query() {
    NEW_QUERY=$(echo "$QUERY" | rofi -dmenu -p "Search (empty = browse)" "${ROFI_INPUT_KEYS[@]}")
    if [[ "$NEW_QUERY" != "$QUERY" ]]; then
        QUERY="$NEW_QUERY"
        CURRENT_PAGE=1
        LAST_PAGE=1
    fi
}

get_atleast_display() {
    if [[ "$ATLEAST_ENABLED" != "true" ]]; then
        echo "OFF"
    elif [[ "$ATLEAST_VALUE" == "auto" ]]; then
        echo "Auto ($(get_monitor_resolution))"
    else
        echo "$ATLEAST_VALUE"
    fi
}

get_exact_display() {
    if [[ "$EXACT_ENABLED" != "true" ]]; then
        echo "OFF"
    elif [[ -z "$EXACT_VALUE" ]]; then
        echo "none selected"
    else
        local count
        count=$(echo "$EXACT_VALUE" | tr ',' '\n' | wc -l)
        if (( count > 2 )); then
            echo "$count resolutions"
        else
            echo "$EXACT_VALUE"
        fi
    fi
}

run_search() {
    while true; do
        res=0
        search_and_select || res=$?
        case $res in
            0) exit 0 ;;
            1) exit 0 ;;
            2) break ;;
            3|4) continue ;;
        esac
    done
}

while true; do
    page_info=""
    if (( LAST_PAGE > 1 )); then
        page_info=" (page $CURRENT_PAGE/$LAST_PAGE)"
    fi
    
    query_display="${QUERY:-<empty - browse mode>}"
    atleast_display=$(get_atleast_display)
    exact_display=$(get_exact_display)
    
    menu_items="[ SEARCH ]\nQuery: ${query_display}${page_info}\nAtleast: ${atleast_display}\nExact: ${exact_display}\nSorting: ${SORTING}"
    
    if [[ "$SORTING" == "toplist" ]]; then
        toplist_display=$(get_toplist_display "$TOPLIST_RANGE")
        menu_items+="\nToplist Range: ${toplist_display}"
    fi
    
    menu_items+="\nPurity: ${PURITY}\nCategories: ${CATEGORIES}\n---\n[ QUIT ]"

    rofi_exit=0
    CHOICE=$(printf "%b" "$menu_items" | rofi -dmenu -p "Wallhaven [/=query]" -i "${ROFI_MENU_KEYS[@]}") || rofi_exit=$?

    if (( rofi_exit == 10 )); then
        edit_query
        continue
    elif (( rofi_exit == 1 )); then
        exit 0
    fi

    case "$CHOICE" in
    "Query: "*)
        edit_query
        ;;
    "Atleast: "*)
        OLD_ATLEAST="$ATLEAST"
        manage_atleast
        if [[ "$ATLEAST" != "$OLD_ATLEAST" ]]; then
            CURRENT_PAGE=1
            LAST_PAGE=1
        fi
        ;;
    "Exact: "*)
        OLD_EXACT="$EXACT_VALUE"
        OLD_EXACT_ENABLED="$EXACT_ENABLED"
        manage_exact
        if [[ "$EXACT_VALUE" != "$OLD_EXACT" || "$EXACT_ENABLED" != "$OLD_EXACT_ENABLED" ]]; then
            CURRENT_PAGE=1
            LAST_PAGE=1
        fi
        ;;
    "Sorting: "*)
        NEW_SORTING=$(printf "relevance\ndate_added\nrandom\nviews\nfavorites\ntoplist\n" | rofi -dmenu -p "Sorting" "${ROFI_SELECT_KEYS[@]}")
        if [[ -n "$NEW_SORTING" && "$NEW_SORTING" != "$SORTING" ]]; then
            SORTING="$NEW_SORTING"
            CURRENT_PAGE=1
            LAST_PAGE=1
            save_settings
        fi
        ;;
    "Toplist Range: "*)
        OLD_TOPLIST="$TOPLIST_RANGE"
        manage_toplist_range
        if [[ "$TOPLIST_RANGE" != "$OLD_TOPLIST" ]]; then
            CURRENT_PAGE=1
            LAST_PAGE=1
        fi
        ;;
    "Purity: "*)
        OLD_PURITY="$PURITY"
        manage_purity
        if [[ "$PURITY" != "$OLD_PURITY" ]]; then
            CURRENT_PAGE=1
            LAST_PAGE=1
            save_settings
        fi
        ;;
    "Categories: "*)
        OLD_CATEGORIES="$CATEGORIES"
        manage_categories
        if [[ "$CATEGORIES" != "$OLD_CATEGORIES" ]]; then
            CURRENT_PAGE=1
            LAST_PAGE=1
            save_settings
        fi
        ;;
    "[ SEARCH ]")
        run_search
        ;;
    "[ QUIT ]" | *) exit 0 ;;
    esac
done
