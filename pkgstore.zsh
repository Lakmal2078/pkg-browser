#!/usr/bin/env zsh
# -*- coding: utf-8 -*-
# ================================================================
#  pkg-browser.zsh  –  Interactive Debian/Ubuntu/Termux pkg browser
#  Features : dashboard · spinner · themes · stats · activity log
#             tree deps · preview tabs · file search · pkg icons
#             coloured status badges · size bars · ASCII art
#  Deps     : fzf, apt, dpkg   Optional: bat/batcat, curl, glow
# ================================================================

setopt nullglob extendedglob

# ── UTF-8 locale ────────────────────────────────────────────────
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"

# ── ANSI helpers ────────────────────────────────────────────────
_esc()  { printf '\033[%sm' "$1"; }
_bold() { printf '\033[1m'; }
_rst()  { printf '\033[0m'; }

# zsh prompt colours (only for print -P outside fzf)
C_TITLE="%F{cyan}%B";  C_OK="%F{green}%B"
C_WARN="%F{yellow}%B"; C_ERR="%F{red}%B"; C_RST="%f%b"

# ── Runtime flags ───────────────────────────────────────────────
SUDO="sudo"
[[ -n "$PREFIX" && "$PREFIX" == *termux* ]] && SUDO=""

# Check for bat/batcat
USE_BAT=0; BAT_CMD=""
for _b in bat batcat; do
  command -v "$_b" &>/dev/null && { BAT_CMD="$_b"; USE_BAT=1; break }
done
export USE_BAT BAT_CMD

# Check for glow (Markdown rendering)
USE_GLOW=0; GLOW_CMD=""
if command -v glow &>/dev/null; then
  GLOW_CMD="glow"
  USE_GLOW=1
fi
export USE_GLOW GLOW_CMD

IS_TERMUX=0
[[ -n "$PREFIX" && "$PREFIX" == *termux* ]] && IS_TERMUX=1
export IS_TERMUX

# ── Cache paths ─────────────────────────────────────────────────
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pkg-browser"
mkdir -p "$CACHE_DIR"
CACHE_ALL="$CACHE_DIR/all.txt"
CACHE_INST="$CACHE_DIR/installed.txt"
CACHE_AVAIL="$CACHE_DIR/available.txt"
CACHE_TS="$CACHE_DIR/timestamp"
CACHE_FILES="$CACHE_DIR/files.txt"
CACHE_FILES_TS="$CACHE_DIR/files_timestamp"
CACHE_PREVIEW_DIR="$CACHE_DIR/previews"
mkdir -p "$CACHE_PREVIEW_DIR"
ACTIVITY_LOG="$CACHE_DIR/activity.log"
THEME_FILE="$CACHE_DIR/theme"
export CACHE_DIR CACHE_ALL CACHE_INST CACHE_AVAIL ACTIVITY_LOG CACHE_PREVIEW_DIR

# ================================================================
#  1. NERD FONTS ICON SYSTEM
# ================================================================
# Returns modern Nerd Font v3 icon and colour code for a package
_pkg_icon() {
  local pkg="$1"
  case "$pkg" in
    python*|py-*|py3-*)        echo " \033[33m"  ;;  # Python (Yellow)
    ruby*|gem-*)               echo " \033[31m"  ;;  # Ruby (Red)
    node*|npm*|nodejs*)        echo " \033[32m"  ;;  # NodeJS (Green)
    java*|openjdk*|jdk*|jre*)  echo " \033[33m"  ;;  # Java (Yellow)
    nginx*|apache*|httpd*)     echo "󰖟 \033[36m"  ;;  # Web (Cyan)
    mysql*|mariadb*|postgres*|sqlite*) echo " \033[35m" ;; # DB (Magenta)
    git|git-*)                 echo " \033[34m"  ;;  # Git (Blue)
    curl|wget|aria2*)          echo "󰇚 \033[36m"  ;;  # Download (Cyan)
    gcc*|g++*|clang*|llvm*)    echo " \033[31m"  ;;  # C/C++ (Red)
    make|cmake|ninja*|meson*)  echo "󱁤 \033[33m"  ;;  # Tools (Yellow)
    vim|neovim|nano|emacs*)    echo " \033[32m"  ;;  # Editor (Green)
    tmux|screen|zellij*)       echo "󰞷 \033[36m"  ;;  # Terminal (Cyan)
    docker*|podman*|kubectl*)  echo " \033[34m"  ;;  # Container (Blue)
    ssh*|openssh*|openssl*)    echo "󰌆 \033[31m"  ;;  # Key/Security (Red)
    ffmpeg*|mpv*|vlc*)         echo "󰕼 \033[35m"  ;;  # Media (Magenta)
    lib*)                      echo "󰗚 \033[37m"  ;;  # Library (White)
    linux*|kernel*)            echo " \033[37m"  ;;  # Linux (White)
    zsh*|bash*|fish*|sh-*)     echo " \033[32m"  ;;  # Shell (Green)
    fzf*|fd*|ripgrep*|rg*)     echo "󰍉 \033[36m"  ;;  # Search (Cyan)
    htop*|btop*|top*)          echo "󰄧 \033[33m"  ;;  # Stats (Yellow)
    nmap*|wireshark*|tcpdump*) echo "󰒍 \033[31m"  ;;  # Network (Red)
    rust*|cargo*)              echo " \033[31m"  ;;  # Rust (Red)
    go|golang*)                echo " \033[36m"  ;;  # Go (Cyan)
    *)                         echo "󰏖 \033[0m"   ;;  # Default Package (White)
  esac
}
export -f _pkg_icon 2>/dev/null || true

# ================================================================
#  THEME SYSTEM
# ================================================================
typeset -A THEMES
THEMES[cyber]="fg:#cdd6f4,fg+:#cba6f7,bg+:#313244,hl:#89b4fa,hl+:#89dceb,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#89b4fa,border:#6c7086|\033[1;36m|\033[36m|\033[1;35m"
THEMES[nord]="fg:#d8dee9,fg+:#88c0d0,bg+:#3b4252,hl:#81a1c1,hl+:#88c0d0,prompt:#81a1c1,pointer:#bf616a,marker:#a3be8c,header:#5e81ac,border:#4c566a|\033[1;34m|\033[34m|\033[1;36m"
THEMES[gruvbox]="fg:#ebdbb2,fg+:#fabd2f,bg+:#3c3836,hl:#83a598,hl+:#8ec07c,prompt:#fabd2f,pointer:#fb4934,marker:#b8bb26,header:#83a598,border:#504945|\033[1;33m|\033[33m|\033[1;32m"
THEMES[rose]="fg:#e0def4,fg+:#c4a7e7,bg+:#26233a,hl:#9ccfd8,hl+:#ebbcba,prompt:#c4a7e7,pointer:#eb6f92,marker:#9ccfd8,header:#9ccfd8,border:#403d52|\033[1;35m|\033[35m|\033[1;36m"
THEMES[mono]="fg:#c0c0c0,fg+:#ffffff,bg+:#2a2a2a,hl:#888888,hl+:#ffffff,prompt:#aaaaaa,pointer:#ffffff,marker:#888888,header:#aaaaaa,border:#444444|\033[1;37m|\033[37m|\033[0;37m"

_load_theme() {
  local name="${1:-cyber}"
  [[ -z "${THEMES[$name]}" ]] && name="cyber"
  CURRENT_THEME="$name"
  local parts=("${(@s:|:)THEMES[$name]}")
  FZF_COLORS="$parts[1]"
  HDR_CLR="$(printf '%b' "$parts[2]")"
  BDR_CLR="$(printf '%b' "$parts[3]")"
  STA_CLR="$(printf '%b' "$parts[4]")"
  export CURRENT_THEME FZF_COLORS HDR_CLR BDR_CLR STA_CLR
}

_save_theme()  { echo "$CURRENT_THEME" > "$THEME_FILE" }
_saved_theme() { [[ -f "$THEME_FILE" ]] && cat "$THEME_FILE" || echo "cyber" }

# ================================================================
#  ANIMATED SPINNER
# ================================================================
_SPINNER_PID=""
_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

_spinner_start() {
  local msg="${1:-Loading}"
  {
    local i=0
    while true; do
      printf '\r\033[K  \033[1;36m%s\033[0m  %s' \
        "${_SPINNER_FRAMES[$((i % ${#_SPINNER_FRAMES} + 1))]}" "$msg" >&2
      sleep 0.1
      (( i++ ))
    done
  } &
  _SPINNER_PID=$!
  trap '_spinner_stop' INT TERM EXIT
}

_spinner_stop() {
  if [[ -n "$_SPINNER_PID" ]] && kill -0 "$_SPINNER_PID" 2>/dev/null; then
    kill "$_SPINNER_PID" 2>/dev/null
    wait "$_SPINNER_PID" 2>/dev/null
    _SPINNER_PID=""
  fi
  printf '\r\033[K' >&2
}

# ================================================================
#  ACTIVITY LOG
# ================================================================
_log_activity() {
  local action="$1" pkg="$2"
  printf '%s  %-8s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$action" "$pkg" >> "$ACTIVITY_LOG"
  if [[ -f "$ACTIVITY_LOG" ]]; then
    local tmp; tmp=$(mktemp)
    tail -200 "$ACTIVITY_LOG" > "$tmp" && mv "$tmp" "$ACTIVITY_LOG"
  fi
}
export -f _log_activity 2>/dev/null || true

_show_activity() {
  [[ ! -s "$ACTIVITY_LOG" ]] && return
  local cols; cols=$(tput cols 2>/dev/null || echo 80)
  local w=$(( cols < 72 ? cols - 4 : 68 ))
  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n'
  printf '%s|%s  Recent Activity%-*s%s|\n' "$BDR_CLR" "$HDR_CLR" $(( w - 17 )) '' "$BDR_CLR"
  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n'
  tail -6 "$ACTIVITY_LOG" | while IFS= read -r line; do
    local ts="${line:0:16}"
    local act="${line:18:8}"
    local pkg="${line:28}"
    local ac
    case "${act// /}" in
      install) ac=$'\033[32m' ;;
      remove)  ac=$'\033[31m' ;;
      search)  ac=$'\033[33m' ;;
      *)       ac=$'\033[37m' ;;
    esac
    printf '%s|  \033[2m%s\033[0m  %s%-8s\033[0m  %-*s%s|\n' \
      "$BDR_CLR" "$ts" "$ac" "${act// /}" $(( w - 32 )) "$pkg" "$BDR_CLR"
  done
  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n\033[0m'
}

# ================================================================
#  STATS BOX
# ================================================================
_stats_box() {
  local total inst avail upgr cols w
  total=$(wc -l < "$CACHE_ALL" 2>/dev/null || echo 0)
  inst=$(wc -l  < "$CACHE_INST" 2>/dev/null || echo 0)
  avail=$(wc -l < "$CACHE_AVAIL" 2>/dev/null || echo 0)
  upgr=0
  if (( ! IS_TERMUX )); then
    upgr=$(apt list --upgradable 2>/dev/null | grep -c 'upgradable' || echo 0)
  fi

  cols=$(tput cols 2>/dev/null || echo 80)
  w=$(( cols < 72 ? cols - 4 : 68 ))

  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n'
  printf '%s|%s  Package Statistics%-*s%s|\n' "$BDR_CLR" "$STA_CLR" $(( w - 20 )) '' "$BDR_CLR"
  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n'

  local bar_max=$(( w - 34 ))
  local i_bar=$(( total > 0 ? inst * bar_max / total : 0 ))
  local a_bar=$(( bar_max - i_bar ))
  printf '%s|  \033[32mInstalled  %5d  [' "$BDR_CLR" "$inst"
  printf '%0.s#' $(seq 1 $i_bar)
  printf '%0.s.' $(seq 1 $a_bar)
  printf ']\033[0m%s  |\n' "$BDR_CLR"

  printf '%s|  \033[36mAvailable  %5d\033[0m%-*s%s|\n' \
    "$BDR_CLR" "$avail" $(( w - 19 )) '' "$BDR_CLR"
  printf '%s|  \033[33mTotal      %5d\033[0m%-*s%s|\n' \
    "$BDR_CLR" "$total" $(( w - 19 )) '' "$BDR_CLR"
  (( upgr > 0 )) && \
    printf '%s|  \033[31mUpgradable %5d\033[0m%-*s%s|\n' \
      "$BDR_CLR" "$upgr" $(( w - 19 )) '' "$BDR_CLR"
  printf '%s+' "$BDR_CLR"; printf '%0.s-' $(seq 1 $w); printf '+\n\033[0m'
}

# ================================================================
#  THEME SELECTOR
# ================================================================
_theme_selector() {
  local names=("${(@k)THEMES}")
  local choice
  choice=$(printf '%s\n' "${names[@]}" | sort \
    | fzf \
        --prompt="  Select theme > " \
        --header="  [ENTER] apply   [ESC] cancel" \
        --header-lines=1 \
        --height=12 \
        --border=double \
        --color="$FZF_COLORS" \
        --preview="echo 'Theme: {}'" \
        --preview-window="right:20%:wrap" \
        2>/dev/null)
  if [[ -n "$choice" ]]; then
    _load_theme "$choice"
    _save_theme
    print -P "${C_OK}Theme set: $choice${C_RST}"
  fi
}

# ================================================================
#  ASCII ART GENERATOR  (per-package)
# ================================================================
_pkg_ascii_art() {
  local pkg="$1"
  case "$pkg" in
    git|git-*)
      printf '\033[33m'
      printf '   _____ _ _\n'
      printf '  / ____(_) |\n'
      printf ' | |  __ _| |_\n'
      printf ' | | |_ | | __|\n'
      printf ' | |__| | | |_\n'
      printf '  \_____|_|\__|\n'
      printf '\033[0m  Git Version Control\n'
      ;;
    python*|py3-*)
      printf '\033[33m'
      printf '  ____        _   _\n'
      printf ' |  _ \ _   _| |_| |__   ___  _ __\n'
      printf ' | |_) | | | | __| '"'"'_ \ / _ \| '"'"'_ \ \n'
      printf ' |  __/| |_| | |_| | | | (_) | | | |\n'
      printf ' |_|    \__, |\__|_| |_|\___/|_| |_|\n'
      printf '        |___/\n'
      printf '\033[0m  Python Interpreter\n'
      ;;
    nginx*)
      printf '\033[32m'
      printf '  _ __   __ _(_)_ __ __  __\n'
      printf ' | '"'"'_ \ / _` | | '"'"'_ \\ \/ /\n'
      printf ' | | | | (_| | | | | |>  < \n'
      printf ' |_| |_|\__, |_|_| |_/_/\_\ \n'
      printf '        |___/\n'
      printf '\033[0m  Web Server\n'
      ;;
    vim|neovim)
      printf '\033[32m'
      printf '  __   _____ __  __\n'
      printf '  \ \ / /_ _|  \/  |\n'
      printf '   \ V / | || |\/| |\n'
      printf '    \_/ |___|_|  |_|\n'
      printf '\033[0m  Text Editor\n'
      ;;
    curl)
      printf '\033[36m'
      printf '   ___ _   _ _ __ _ \n'
      printf '  / __| | | | '"'"'__| |\n'
      printf ' | (__| |_| | |  | |\n'
      printf '  \___|\__,_|_|  |_|\n'
      printf '\033[0m  URL Transfer Tool\n'
      ;;
    gcc*|clang*)
      printf '\033[31m'
      printf '   ____\n'
      printf '  / ___|  ___ ___\n'
      printf ' | |  _ / __/ __|\n'
      printf ' | |_| | (_| (__\n'
      printf '  \____|\___\___|\n'
      printf '\033[0m  C Compiler\n'
      ;;
    *)
      local icon_info; icon_info=$(_pkg_icon "$pkg")
      local icon="${icon_info%% *}"
      local icon_color="${icon_info#* }"
      printf '%b  %s  %s\033[0m\n' "$icon_color" "$icon" "$pkg"
      ;;
  esac
}
export -f _pkg_ascii_art 2>/dev/null || true

# ================================================================
#  2. TRUE COLOR (24-BIT) GRADIENT GENERATOR
# ================================================================
_gradient_print() {
  local text="$1"
  local len=${#text}
  local r_start=100 g_start=180 b_start=255 # Light Cyan/Blue
  local r_end=230   g_end=80   b_end=255   # Soft Purple/Magenta
  local i
  for (( i=1; i<=len; i++ )); do
    local char="${text:$((i-1)):1}"
    local r=$(( r_start + (r_end - r_start) * (i - 1) / (len > 1 ? len - 1 : 1) ))
    local g=$(( g_start + (g_end - g_start) * (i - 1) / (len > 1 ? len - 1 : 1) ))
    local b=$(( b_start + (b_end - b_start) * (i - 1) / (len > 1 ? len - 1 : 1) ))
    printf '\033[38;2;%d;%d;%dm%s' "$r" "$g" "$b" "$char"
  done
  printf '\033[0m\n'
}
export -f _gradient_print 2>/dev/null || true

# ================================================================
#  3. SMOOTH UNICODE PROGRESS BAR
# ================================================================
_size_bar() {
  local kb="$1"
  local bar_width=20
  local max_kb=10240 # Scale: 0-10MB
  local total_steps=160 # bar_width * 8 steps
  local steps=$(( kb >= max_kb ? total_steps : kb * total_steps / max_kb ))
  local full_blocks=$(( steps / 8 ))
  local partial_step=$(( steps % 8 ))
  local empty_blocks=$(( bar_width - full_blocks - (partial_step > 0 ? 1 : 0) ))

  local bar=""
  local i
  for (( i=0; i<full_blocks; i++ )); do bar+="█"; done
  if (( partial_step > 0 )); then
    local -a fraction_chars; fraction_chars=("▏" "▎" "▍" "▌" "▋" "▊" "▉")
    bar+="${fraction_chars[$partial_step]}"
  fi
  for (( i=0; i<empty_blocks; i++ )); do bar+="░"; done

  local pct=$(( kb >= max_kb ? 100 : kb * 100 / max_kb ))

  # Colour size logic
  local clr
  if   (( kb >= 51200 )); then clr="\033[31m"   # >50MB red
  elif (( kb >= 10240 )); then clr="\033[33m"   # >10MB yellow
  elif (( kb >= 1024  )); then clr="\033[32m"   # >1MB  green
  else                         clr="\033[36m"   # small cyan
  fi

  if (( USE_GLOW )); then
    printf '%s %d%%' "$bar" "$pct"
  else
    printf '%s%s\033[0m %d%%' "$clr" "$bar" "$pct"
  fi
}
export -f _size_bar 2>/dev/null || true

# ================================================================
#  DASHBOARD  (startup screen with True Color banner)
# ================================================================
_dashboard() {
  clear
  local cols; cols=$(tput cols 2>/dev/null || echo 80)
  local w=$(( cols < 76 ? cols - 2 : 74 ))

  # ── True Color Gradient Banner ──────────────────────────────────
  local -a banner_lines=(
    "  ____  _  _____ ____  ____   _____        _______ _____ _____  "
    " |  _ \| |/ / __|  _ \|  _ \ / _ \ \      / / ____|_   _|  __ \ "
    " | |_) | ' /| |_ | |_) | |_) | | | \ \ /\ / /|  _|   | | | |__) |"
    " |  __/| . \|  _||  _ <|  _ <| |_| |\ V  V / | |___  | | |  _  / "
    " |_|   |_|\_|___|_| \_|_| \_\\___/  \_/\_/  |_____| |_| |_|  \_\ "
  )

  for line in "${banner_lines[@]}"; do
    local pad=$(( (w - 65) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s' "$pad" ""
    _gradient_print "$line"
  done
  echo ""

  # ── Subtitle & Platform ──────────────────────────────────────────
  local plat="Debian/Ubuntu"
  (( IS_TERMUX )) && plat="Termux/Android"
  printf '%s  Interactive Package Browser  |  %s  |  Theme: %s\033[0m\n\n' \
    "$HDR_CLR" "$plat" "$CURRENT_THEME"

  # ── Stats & Activity ─────────────────────────────────────────────
  _stats_box
  echo ""
  _show_activity
  echo ""

  # ── Cheatsheet ───────────────────────────────────────────────────
  printf '%s  Keybindings:\033[0m\n' "$HDR_CLR"
  printf '  \033[2m%-22s\033[0m  %s\n' \
    "ENTER"        "Install / Remove selected" \
    "TAB"          "Multi-select toggle" \
    "CTRL-F"       "Cycle filter (All/Installed/Available)" \
    "CTRL-S"       "Search by file path" \
    "CTRL-T"       "Cycle preview tab (Info/Deps/Files/Log)" \
    "CTRL-R"       "Refresh package cache" \
    "CTRL-Y"       "Open theme selector" \
    "ESC"          "Quit"
  echo ""

  printf '%s  Press ENTER to open browser...\033[0m ' "$HDR_CLR"
  read -r
}

# ================================================================
#  CACHE MANAGEMENT
# ================================================================
_cache_stale() {
  [[ ! -f "$CACHE_TS" ]] && return 0
  local age=$(( $(date +%s) - $(cat "$CACHE_TS") ))
  (( age > 3600 ))
}

_refresh_cache() {
  _spinner_start "Refreshing package cache"
  if (( IS_TERMUX )); then
    local apt_out
    apt_out=$(apt-cache search '' 2>/dev/null)
    if [[ -n "$apt_out" ]]; then
      echo "$apt_out" \
        | awk '{printf "%-35s  %s\n", $1, substr($0,index($0,$2))}' \
        | sort -k1,1 > "$CACHE_ALL"
    else
      pkg list-all 2>/dev/null \
        | awk 'NR>1{split($1,a,"/");printf "%-35s  %s %s\n",a[1],$2,$3}' \
        | sort -k1,1 > "$CACHE_ALL"
    fi
    dpkg-query -W -f='${Package}\n' 2>/dev/null | sort > "$CACHE_INST"
  else
    apt-cache search '' 2>/dev/null \
      | awk '{printf "%-35s  %s\n", $1, substr($0,index($0,$2))}' \
      | sort -k1,1 > "$CACHE_ALL"
    dpkg-query -W -f='${Package}\n' 2>/dev/null | sort > "$CACHE_INST"
  fi
  comm -23 <(awk '{print $1}' "$CACHE_ALL") "$CACHE_INST" > "$CACHE_AVAIL"
  date +%s > "$CACHE_TS"
  _spinner_stop
  print -P "${C_OK}[ok] Cache ready ($(wc -l < "$CACHE_ALL") packages)${C_RST}"
}

_ensure_cache() {
  if _cache_stale || [[ ! -s "$CACHE_ALL" ]]; then
    _refresh_cache
  fi
}

_get_pkg_info() {
  local pkg="$1"
  local cache_file="$CACHE_PREVIEW_DIR/${pkg}.txt"
  local max_age=300
  local now; now=$(date +%s)
  local mtime
  mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
  if [[ ! -f "$cache_file" ]] || (( now - mtime > max_age )); then
    apt-cache show "$pkg" 2>/dev/null > "$cache_file"
  fi
  cat "$cache_file"
}
export -f _get_pkg_info 2>/dev/null || true

# ================================================================
#  FIELD PARSER (with Glow/Markdown and ANSI modes)
# ================================================================
_show_fields() {
  awk '
    /^(Version|Section|Installed-Size|Maintainer|Homepage|Depends|Recommends|Suggests|Description):/ {
      colon=index($0,":")
      key=substr($0,1,colon-1); val=substr($0,colon+2)
      in_desc=(key=="Description")
      size_kb=0
      if (key=="Installed-Size") {
        size_kb=val+0
        if      (size_kb>=1048576) val=sprintf("%.1f GB  (%s KB)",size_kb/1048576,val)
        else if (size_kb>=1024)    val=sprintf("%.1f MB  (%s KB)",size_kb/1024,val)
        else                       val=sprintf("%s KB",val)
      }
      # Toggle styling for Glow vs Normal Terminal
      if (ENVIRON["USE_GLOW"] == "1") {
        printf "**%s:** %s  \n", key, val; next
      } else {
        printf "  \033[1;33m%-18s\033[0m  \033[36m%s\033[0m\n", key":", val; next
      }
    }
    in_desc && /^ / {
      if ($0==" .") {
        if (ENVIRON["USE_GLOW"] == "1") print "\n"; else print ""
      } else {
        sub(/^ /,"");
        if (ENVIRON["USE_GLOW"] == "1") printf "> %s  \n", $0; else printf "    \033[37m%s\033[0m\n", $0
      }; next
    }
    /^[A-Z]/ { in_desc=0 }
  '
}
export -f _show_fields 2>/dev/null || true

_show_size_bar() {
  local pkg="$1"
  local kb
  kb=$(_get_pkg_info "$pkg" \
    | awk '/^Installed-Size:/{print $2; exit}')
  [[ -z "$kb" || "$kb" == "0" ]] && return
  if (( USE_GLOW )); then
    printf '**%-18s**  ' "Size bar:"
  else
    printf '  \033[1;33m%-18s\033[0m  ' "Size bar:"
  fi
  _size_bar "$kb"
  printf '\n'
}
export -f _show_size_bar 2>/dev/null || true

# ================================================================
#  DEPENDENCY TREE GENERATOR
# ================================================================
_dep_tree() {
  local pkg="$1"
  _get_pkg_info "$pkg" \
  | awk '
      /^Depends:/ {
        sub(/^Depends: /,"")
        n=split($0,deps,", ")
        for (i=1;i<=n;i++) {
          sub(/ \(.*\)/,"",deps[i])
          sub(/ \|.*$/,"",deps[i])
          gsub(/^ +| +$/,"",deps[i])
          if (deps[i]!="") a[++c]=deps[i]
        }
        for (i=1;i<=c;i++) {
          conn = (i==c) ? "  └── " : "  ├── "
          printf "%s%s\n", conn, a[i]
        }
        exit
      }
    '
}
export -f _dep_tree 2>/dev/null || true

_rec_tree() {
  local pkg="$1"
  _get_pkg_info "$pkg" \
  | awk '
      /^Recommends:/ {
        sub(/^Recommends: /,"")
        n=split($0,deps,", ")
        for (i=1;i<=n;i++) {
          sub(/ \(.*\)/,"",deps[i])
          sub(/ \|.*$/,"",deps[i])
          gsub(/^ +| +$/,"",deps[i])
          if (deps[i]!="") a[++c]=deps[i]
        }
        for (i=1;i<=c;i++) {
          conn = (i==c) ? "  └── " : "  ├── "
          printf "%s%s\n", conn, a[i]
        }
        exit
      }
    '
}
export -f _rec_tree 2>/dev/null || true

# ================================================================
#  5. TAB-BASED PREVIEWS (WITH GLOW INTEGRATION)
# ================================================================
TAB_FILE="$CACHE_DIR/preview_tab"
export TAB_FILE

_next_tab() {
  local cur; cur=$(cat "$TAB_FILE" 2>/dev/null || echo "info")
  case "$cur" in
    info)  echo "deps"  > "$TAB_FILE";;
    deps)  echo "files" > "$TAB_FILE";;
    files) echo "log"   > "$TAB_FILE";;
    *)     echo "info"  > "$TAB_FILE";;
  esac
}
export -f _next_tab 2>/dev/null || true

_preview_draw_header() {
  local pkg="$1" tab="$2"
  local icon_info; icon_info=$(_pkg_icon "$pkg")
  local icon="${icon_info%% *}"
  local icon_color="${icon_info#* }"

  if (( USE_GLOW )); then
    local t_info="Info" t_deps="Deps" t_files="Files" t_log="Log"
    case "$tab" in
      info)  t_info="**[Info]**";;
      deps)  t_deps="**[Deps]**";;
      files) t_files="**[Files]**";;
      log)   t_log="**[Log]**";;
    esac
    printf '| %s | %s | %s | %s |  *Package:* %s `%s` |\n' "$t_info" "$t_deps" "$t_files" "$t_log" "$icon" "$pkg"
    printf '| :---: | :---: | :---: | :---: | :--- |\n'
  else
    local sep; sep=$(awk 'BEGIN{for(i=0;i<56;i++) printf "\xe2\x94\x80"; print ""}')
    local t_info="  Info " t_deps="  Deps " t_files=" Files " t_log="  Log  "
    case "$tab" in
      info)  t_info=">[Info]<";;
      deps)  t_deps=">[Deps]<";;
      files) t_files=">[Files]<";;
      log)   t_log=">[Log  ]<";;
    esac
    echo "$sep"
    printf '  %s  %s  %s  %s    \033[1mpackage:\033[0m %b%s \033[1;36m%s\033[0m\n' \
      "$t_info" "$t_deps" "$t_files" "$t_log" "$icon_color" "$icon" "$pkg"
    echo "$sep"
  fi
}
export -f _preview_draw_header 2>/dev/null || true

_preview_draw_status() {
  local inst="$1" is_inst="$2"
  local status_str status_clr status_icon
  if (( is_inst )); then
    local ver; ver=$(echo "$inst" | awk '{print $NF}')
    status_str="installed ($ver)"
    status_clr=$'\033[32m'
    status_icon="🟢"
  else
    status_str="not installed"
    status_clr=$'\033[31m'
    status_icon="🔴"
  fi
  if (( USE_GLOW )); then
    printf '\n### Status: %s %s\n\n' "$status_icon" "$status_str"
  else
    printf '  \033[1;33m%-18s\033[0m  %s%s %s\033[0m\n\n' \
      "status:" "$status_clr" "$status_icon" "$status_str"
  fi
}
export -f _preview_draw_status 2>/dev/null || true

_preview_tab_info() {
  local pkg="$1"
  if (( ! USE_GLOW )); then
    _pkg_ascii_art "$pkg"
    echo ""
  fi
  _get_pkg_info "$pkg" | _show_fields
  echo ""
  _show_size_bar "$pkg"
}
export -f _preview_tab_info 2>/dev/null || true

_preview_tab_deps() {
  local pkg="$1"
  if (( USE_GLOW )); then
    printf '### Depends\n'
    local dt; dt=$(_dep_tree "$pkg")
    [[ -n "$dt" ]] && echo "$dt" | sed 's/├──/* ├──/g; s/└──/* └──/g' || printf '  *(none)*\n'
    printf '\n### Recommends\n'
    local rt; rt=$(_rec_tree "$pkg")
    [[ -n "$rt" ]] && echo "$rt" | sed 's/├──/* ├──/g; s/└──/* └──/g' || printf '  *(none)*\n'
    echo ""
    if (( ! IS_TERMUX )); then
      local rdeps
      rdeps=$(apt-cache rdepends \
                --no-suggests --no-conflicts --no-breaks \
                --no-replaces --no-enhances "$pkg" 2>/dev/null \
              | awk 'NR>1&&/^  /{gsub(/^ +/,"");print}' \
              | head -10)
      if [[ -n "$rdeps" ]]; then
        printf '### Needed-by\n'
        local lines=("${(@f)rdeps}")
        local n=${#lines[@]}
        for (( i=1; i<=n; i++ )); do
          printf '  * %s\n' "${lines[$i]}"
        done
      fi
    fi
  else
    printf '  \033[1;33mDepends:\033[0m\n'
    local dt; dt=$(_dep_tree "$pkg")
    [[ -n "$dt" ]] && echo "$dt" | sed 's/├──/\033[33m├──\033[36m/g; s/└──/\033[33m└──\033[36m/g' || printf '  \033[2m(none)\033[0m\n'
    echo ""
    printf '  \033[1;35mRecommends:\033[0m\n'
    local rt; rt=$(_rec_tree "$pkg")
    [[ -n "$rt" ]] && echo "$rt" | sed 's/├──/\033[33m├──\033[35m/g; s/└──/\033[33m└──\033[35m/g' || printf '  \033[2m(none)\033[0m\n'
    echo ""
    if (( ! IS_TERMUX )); then
      local rdeps
      rdeps=$(apt-cache rdepends \
                --no-suggests --no-conflicts --no-breaks \
                --no-replaces --no-enhances "$pkg" 2>/dev/null \
              | awk 'NR>1&&/^  /{gsub(/^ +/,"");print}' \
              | head -10)
      if [[ -n "$rdeps" ]]; then
        printf '  \033[1;36mNeeded-by:\033[0m\n'
        local lines=("${(@f)rdeps}")
        local n=${#lines[@]}
        for (( i=1; i<=n; i++ )); do
          local conn
          (( i==n )) && conn="  \xe2\x94\x94\xe2\x94\x80 " || conn="  \xe2\x94\x9c\xe2\x94\x80 "
          printf '\033[33m%s\033[0m%s\n' "$conn" "${lines[$i]}"
        done
      fi
    fi
  fi
}
export -f _preview_tab_deps 2>/dev/null || true

_preview_tab_files() {
  local pkg="$1" is_inst="$2"
  if (( is_inst )); then
    local flist total
    flist=$(dpkg -L "$pkg" 2>/dev/null | grep -v '^\.$' | sort)
    total=$(echo "$flist" | wc -l)
    if (( USE_GLOW )); then
      printf '### Files (%d files)\n\n' "$total"
      echo "$flist" | head -30 \
        | awk '{
            if ($0 ~ /\/$/) printf "  * **%s**\n", $0
            else if ($0 ~ /\.(sh|zsh|bash|py|rb|pl)$/) printf "  * `%s`\n", $0
            else if ($0 ~ /\.(so|a)$/) printf "  * *%s*\n", $0
            else printf "  * %s\n", $0
          }'
      (( total > 30 )) && printf '\n  *... (+%d more)*\n' $(( total - 30 ))
    else
      printf '  \033[1;33m%-18s\033[0m  \033[36m(%d files)\033[0m\n\n' "Files:" "$total"
      echo "$flist" | head -30 \
        | awk '{
            if ($0 ~ /\/$/) printf "  \033[34m%s\033[0m\n", $0
            else if ($0 ~ /\.(sh|zsh|bash|py|rb|pl)$/) printf "  \033[32m%s\033[0m\n", $0
            else if ($0 ~ /\.(so|a)$/) printf "  \033[35m%s\033[0m\n", $0
            else printf "  \033[37m%s\033[0m\n", $0
          }'
      (( total > 30 )) && printf '  \033[2m... (+%d more)\033[0m\n' $(( total - 30 ))
    fi
  else
    if (( USE_GLOW )); then
      printf '\n*Package not installed – no file list*\n'
    else
      printf '  \033[31m(package not installed – no file list)\033[0m\n'
    fi
  fi
}
export -f _preview_tab_files 2>/dev/null || true

_preview_tab_log() {
  local pkg="$1"
  if (( ! IS_TERMUX )) && command -v curl &>/dev/null; then
    local uri
    uri=$(apt-get changelog --print-uris "$pkg" 2>/dev/null \
          | awk '{print $1}' | tr -d "'")
    if [[ -n "$uri" && "$uri" != "null" ]]; then
      if (( USE_GLOW )); then
        printf '### Changelog (Live)\n\n'
        printf '```text\n'
        curl -s --max-time 5 "$uri" 2>/dev/null | head -30
        printf '```\n'
      else
        printf '  \033[1;33mChangelog\033[0m (live):\n\n'
        curl -s --max-time 5 "$uri" 2>/dev/null \
          | head -30 | awk '{printf "  \033[37m%s\033[0m\n", $0}'
      fi
    else
      if (( USE_GLOW )); then
        printf '\n*(Changelog URI unavailable)*\n'
      else
        printf '  \033[2m(changelog URI unavailable)\033[0m\n'
      fi
    fi
  else
    if (( USE_GLOW )); then
      printf '\n*(Changelog fetch not available on this platform)*\n'
    else
      printf '  \033[2m(changelog fetch not available on this platform)\033[0m\n'
    fi
  fi
  echo ""
  if (( USE_GLOW )); then
    printf '### Local Activity\n\n'
    if grep -q " $pkg$" "$ACTIVITY_LOG" 2>/dev/null; then
      printf '```text\n'
      grep " $pkg$" "$ACTIVITY_LOG" | tail -5
      printf '```\n'
    else
      printf '*(No recorded activity)*\n'
    fi
  else
    printf '  \033[1;33mLocal activity:\033[0m\n'
    if grep -q " $pkg$" "$ACTIVITY_LOG" 2>/dev/null; then
      grep " $pkg$" "$ACTIVITY_LOG" | tail -5 \
        | awk '{printf "  \033[37m%s\033[0m\n", $0}'
    else
      printf '  \033[2m(no recorded activity)\033[0m\n'
    fi
  fi
}
export -f _preview_tab_log 2>/dev/null || true

_pkg_preview() {
  local pkg="$1"
  [[ -z "$pkg" ]] && return
  pkg="${pkg// /}"; pkg="${pkg%% *}"
  [[ -z "$pkg" ]] && return

  local tab; tab=$(cat "$TAB_FILE" 2>/dev/null || echo "info")
  local inst; inst=$(dpkg-query -W -f='${Status} ${Version}' "$pkg" 2>/dev/null)
  local is_inst=0
  echo "$inst" | grep -q '^install ok' && is_inst=1

  {
    _preview_draw_header "$pkg" "$tab"
    _preview_draw_status "$inst" "$is_inst"
    case "$tab" in
      info)  _preview_tab_info  "$pkg"             ;;
      deps)  _preview_tab_deps  "$pkg"             ;;
      files) _preview_tab_files "$pkg" "$is_inst"  ;;
      log)   _preview_tab_log   "$pkg"             ;;
    esac
  } | if (( USE_GLOW )); then
    "$GLOW_CMD" -s dark -
  elif (( USE_BAT )); then
    "$BAT_CMD" --color=always --style=plain --language=yaml
  else
    cat
  fi
}
export -f _pkg_preview 2>/dev/null || true


# ================================================================
#  BUILD LIST
# ================================================================
_build_list() {
  local mode="$1"
  case "$mode" in
    installed)
      comm -12 "$CACHE_INST" <(awk '{print $1}' "$CACHE_ALL") \
      | awk '
          NR==FNR { want[$1]=1; next }
          $1 in want {
            desc=substr($0,index($0,$2))
            printf "✔ %-33s  %s\n",$1,desc
          }
        ' - "$CACHE_ALL"
      ;;
    available)
      awk '
        NR==FNR { want[$1]=1; next }
        $1 in want {
          desc=substr($0,index($0,$2))
          printf "✘ %-33s  %s\n",$1,desc
        }
      ' "$CACHE_AVAIL" "$CACHE_ALL"
      ;;
    *)
      awk '
        NR==FNR { inst[$1]=1; next }
        {
          desc=substr($0,index($0,$2))
          marker=($1 in inst)?"✔":"✘"
          printf "%s %-33s  %s\n",marker,$1,desc
        }
      ' "$CACHE_INST" "$CACHE_ALL"
      ;;
  esac
}

# ================================================================
#  ACTION (install / remove)
# ================================================================
_do_action() {
  local -a pkgs=("$@")
  [[ ${#pkgs} -eq 0 ]] && return
  local -a to_install=() to_remove=()
  for raw in "${pkgs[@]}"; do
    local p; p=$(echo "$raw" | awk '{print $2}')
    [[ -z "$p" ]] && continue
    if grep -qx "$p" "$CACHE_INST"; then
      to_remove+=("$p")
    else
      to_install+=("$p")
    fi
  done

  if [[ ${#to_install} -gt 0 ]]; then
    print -P "\n${C_OK}[+] Installing: ${to_install[*]}${C_RST}"
    _log_activity "install" "${to_install[*]}"
    (( IS_TERMUX )) && pkg install -y "${to_install[@]}" \
                    || ${SUDO} apt-get install -y "${to_install[@]}"
  fi
  if [[ ${#to_remove} -gt 0 ]]; then
    print -P "\n${C_WARN}[-] Removing:   ${to_remove[*]}${C_RST}"
    print -n "Confirm removal? [y/N] "; read -r ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      _log_activity "remove" "${to_remove[*]}"
      (( IS_TERMUX )) && pkg uninstall -y "${to_remove[@]}" \
                      || ${SUDO} apt-get remove -y "${to_remove[@]}"
    fi
  fi
  rm -f "$CACHE_TS"
  rm -f "$CACHE_FILES" "$CACHE_FILES_TS"
  rm -f "$CACHE_PREVIEW_DIR"/*.txt 2>/dev/null
}

# ================================================================
#  FILE SEARCH
# ================================================================
_file_cache_stale() {
  [[ ! -s "$CACHE_FILES" ]] && return 0
  local age=$(( $(date +%s) - $(cat "$CACHE_FILES_TS" 2>/dev/null || echo 0) ))
  (( age > 3600 ))
}

_file_search() {
  local script_path="$1"
  if _file_cache_stale; then
    _spinner_start "Building file index"
    local info_dir="/var/lib/dpkg/info"
    (( IS_TERMUX )) && info_dir="${PREFIX}/var/lib/dpkg/info"
    for f in "$info_dir"/*.list(N); do
      local pkgname="${${f:t:r}%:*}"
      grep -v '^\.$' "$f" \
        | awk -v p="$pkgname" '{printf "%s\t%s\n",$0,p}'
    done | sort > "$CACHE_FILES"
    date +%s > "$CACHE_FILES_TS"
    _spinner_stop
    print -P "${C_OK}[ok] File index ($(wc -l < "$CACHE_FILES") files)${C_RST}"
  fi
  _log_activity "search" "(file index)"
  local selected
  selected=$(
    awk -F'\t' '{printf "%-55s  (%s)\n",$1,$2}' "$CACHE_FILES" \
    | fzf \
        --ansi --prompt=" 󰍉 [file search] > " \
        --header="  Path/filename fragment  [ESC] back  [ENTER] open pkg" \
        --header-lines=1 \
        --preview="pkg=\$(echo {-1}|tr -d '()'); zsh -c 'source ${(q)script_path}; _pkg_preview \$pkg' 2>/dev/null" \
        --preview-window="down:40%:wrap" \
        --bind="esc:abort" \
        --color="$FZF_COLORS" \
        --pointer="❯" --border=double 2>/dev/null
  )
  [[ -n "$selected" ]] && echo "$selected" | awk '{gsub(/[()]/,"");print $NF}'
}

# ================================================================
#  HEADER / KEYBINDING BAR
# ================================================================
_fzf_header() {
  local mode="$1"
  local tab; tab=$(cat "$TAB_FILE" 2>/dev/null || echo "info")
  printf '  [TAB] select  [ENTER] install/remove  [CTRL-R] refresh  [CTRL-S] files  [CTRL-Y] theme\n'
  printf '  [CTRL-F] filter: %-12s [CTRL-T] preview tab: %-8s [ESC] quit\n' \
    "$mode" "$tab"
}

# ================================================================
#  4. MAIN LOOP (MODERNIZED FZF STYLING)
# ================================================================
main() {
  if ! command -v fzf &>/dev/null; then
    print -P "${C_ERR}Error: fzf required. Run: ${IS_TERMUX:+pkg}${IS_TERMUX:-sudo apt} install fzf${C_RST}"
    exit 1
  fi

  _load_theme "$(_saved_theme)"
  [[ ! -f "$TAB_FILE" ]] && echo "info" > "$TAB_FILE"
  _ensure_cache
  _dashboard

  local mode="all"
  local last_query=""

  while true; do
    local cols; cols=$(tput cols 2>/dev/null || echo 80)
    local preview_pos
    (( cols < 120 )) && preview_pos="down:45%:wrap" \
                     || preview_pos="right:48%:wrap"

    local script_path="${(%):-%x}"
    local preview_cmd="zsh -c 'source ${(q)script_path}; _pkg_preview {2}' 2>/dev/null"

    local tmplist; tmplist=$(mktemp)
    _build_list "$mode" > "$tmplist"

    local toggle_flag;     toggle_flag=$(mktemp);     rm -f "$toggle_flag"
    local filesearch_flag; filesearch_flag=$(mktemp); rm -f "$filesearch_flag"
    local theme_flag;      theme_flag=$(mktemp);      rm -f "$theme_flag"
    local tab_flag;        tab_flag=$(mktemp);        rm -f "$tab_flag"

    local -a fzf_border_label=()
    fzf --border-label="" --version &>/dev/null 2>&1 \
      && fzf_border_label=(--border-label=" 󰏖 pkg-browser [$CURRENT_THEME] " --border-label-pos=3)

    local fzf_out
    fzf_out=$(
      fzf \
        --ansi --multi \
        --query="$last_query" \
        --prompt=" 󰍉 [search] > " \
        --header="$(_fzf_header "$mode")" \
        --header-lines=2 \
        --preview="$preview_cmd" \
        --preview-window="$preview_pos" \
        --bind="tab:toggle+down" \
        --bind="ctrl-r:reload(zsh -c 'source ${(q)script_path} && rm -f ${(q)CACHE_TS} && _ensure_cache >/dev/null && _build_list ${(q)mode}')" \
        --bind="ctrl-f:execute-silent(touch ${(q)toggle_flag})+abort" \
        --bind="ctrl-s:execute-silent(touch ${(q)filesearch_flag})+abort" \
        --bind="ctrl-y:execute-silent(touch ${(q)theme_flag})+abort" \
        --bind="ctrl-t:execute-silent(touch ${(q)tab_flag}; zsh -c 'source ${(q)script_path}; _next_tab')+refresh-preview" \
        --bind="esc:abort" \
        --color="$FZF_COLORS" \
        --marker="󰄬" --pointer="❯" \
        --border=double \
        --margin=1,2 \
        --info=inline-right \
        "${fzf_border_label[@]}" \
        < "$tmplist" 2>/dev/null
    )
    local fzf_exit=$?
    rm -f "$tmplist"

    # ── signal dispatch ──────────────────────────────────────────────
    if [[ -f "$toggle_flag" ]]; then
      rm -f "$toggle_flag" "$filesearch_flag" "$theme_flag" "$tab_flag"
      case "$mode" in
        all)       mode="installed" ;;
        installed) mode="available" ;;
        *)         mode="all"       ;;
      esac
      continue
    fi

    if [[ -f "$filesearch_flag" ]]; then
      rm -f "$toggle_flag" "$filesearch_flag" "$theme_flag" "$tab_flag"
      local found_pkg; found_pkg=$(_file_search "$script_path")
      if [[ -n "$found_pkg" ]]; then
        last_query="$found_pkg"; mode="all"
      fi
      continue
    fi

    if [[ -f "$theme_flag" ]]; then
      rm -f "$toggle_flag" "$filesearch_flag" "$theme_flag" "$tab_flag"
      _theme_selector
      continue
    fi

    rm -f "$toggle_flag" "$filesearch_flag" "$theme_flag" "$tab_flag"

    [[ $fzf_exit -ne 0 ]] && break
    [[ -z "$fzf_out"   ]] && break

    local -a selected
    while IFS= read -r line; do [[ -n "$line" ]] && selected+=("$line"); done <<< "$fzf_out"
    _do_action "${selected[@]}"

    print -P "\n${C_TITLE}Press ENTER to continue...${C_RST}"
    read -r
  done

  _spinner_stop
  print -P "${C_OK}Bye! 󰗠${C_RST}"
}

# ── Entry point ──────────────────────────────────────────────────
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" || "$0" == *pkg-browser* ]]; then
  main "$@"
fi