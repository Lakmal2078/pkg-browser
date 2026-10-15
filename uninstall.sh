#!/usr/bin/env bash
# ================================================================
#  pkg-browser - Production Uninstaller Script
#  Supports: Debian, Ubuntu, Linux Mint, and Termux (Android)
# ================================================================

set -euo pipefail
IFS=$'\n\t'

APP_NAME="pkg-browser"
SHORT_NAME="pkgb"

# ANSI Colors
C_RESET="\e[0m"
C_BOLD="\e[1m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_RED="\e[31m"

log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET}  $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

# Environment detection
IS_TERMUX=0
if [[ -n "${PREFIX:-}" && "$PREFIX" == *termux* ]]; then
    IS_TERMUX=1
    BIN_DIR="${PREFIX}/bin"
    SUDO=""
else
    BIN_DIR="/usr/local/bin"
    SUDO="sudo"
    [[ $EUID -eq 0 ]] && SUDO=""
fi

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pkg-browser"

PURGE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge|-p)
            PURGE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--purge]"
            echo "  --purge, -p    Remove local cache, preview index, and activity logs (~/.cache/pkg-browser)"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            exit 1
            ;;
    esac
done

echo -e "${C_YELLOW}${C_BOLD}Uninstalling ${APP_NAME}...${C_RESET}"

# Remove binaries and symlinks
removed_bin=0
for target in "${BIN_DIR}/${APP_NAME}" "${BIN_DIR}/${SHORT_NAME}"; do
    if [[ -f "$target" || -L "$target" ]]; then
        if (( IS_TERMUX )); then
            rm -f "$target"
        else
            ${SUDO} rm -f "$target"
        fi
        log_info "Removed: ${target}"
        removed_bin=1
    fi
done

if [[ $removed_bin -eq 0 ]]; then
    log_warn "No installed binaries found in ${BIN_DIR}."
fi

# Cache and configuration cleanup
if [[ $PURGE -eq 1 ]]; then
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        log_info "Purged cache directory: ${CACHE_DIR}"
    fi
else
    if [[ -d "$CACHE_DIR" ]]; then
        log_info "Cached package data preserved at: ${CACHE_DIR}"
        log_info "(Run '$0 --purge' to delete all cached data and logs)"
    fi
fi

echo -e "\n${C_GREEN}${C_BOLD}✔ ${APP_NAME} uninstalled successfully.${C_RESET}"
