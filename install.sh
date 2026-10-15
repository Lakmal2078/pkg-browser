#!/usr/bin/env bash
# ================================================================
#  pkg-browser - Production Installer Script
#  Supports: Debian, Ubuntu, Linux Mint, and Termux (Android)
# ================================================================

set -euo pipefail
IFS=$'\n\t'

APP_NAME="pkg-browser"
SHORT_NAME="pkgb"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${REPO_DIR}/pkg-browser.zsh"

# ANSI Colors
C_RESET="\e[0m"
C_BOLD="\e[1m"
C_GREEN="\e[32m"
C_CYAN="\e[36m"
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

# Cleanup on exit or failure
TMP_DIR="$(mktemp -d -t pkg-browser-install-XXXXXX 2>/dev/null || mktemp -d)"
cleanup() {
    local exit_code=$?
    rm -rf "${TMP_DIR:-}"
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code ${exit_code} on line ${BASH_LINENO[0]:-unknown}."
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

preflight_checks() {
    log_info "Running pre-flight checks..."

    # Check source script exists
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        log_error "Source file not found at: ${SOURCE_SCRIPT}"
        exit 1
    fi

    # Check required dependencies
    local missing_req=()
    for cmd in zsh fzf; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_req+=("$cmd")
        fi
    done

    if [[ ${#missing_req[@]} -gt 0 ]]; then
        log_warn "Missing required dependencies: ${missing_req[*]}"
        log_info "Attempting to install missing dependencies..."
        if (( IS_TERMUX )); then
            pkg update -y && pkg install -y "${missing_req[@]}"
        else
            ${SUDO} apt-get update -y && ${SUDO} apt-get install -y "${missing_req[@]}"
        fi
    fi

    # Check optional enhancers
    local missing_opt=()
    for cmd in bat glow curl; do
        if ! command -v "$cmd" >/dev/null 2>&1 && ! command -v "batcat" >/dev/null 2>&1; then
            missing_opt+=("$cmd")
        fi
    done

    if [[ ${#missing_opt[@]} -gt 0 ]]; then
        log_info "Optional recommended tools available for better visuals: ${missing_opt[*]}"
    fi
}

install_application() {
    log_info "Installing ${APP_NAME} to ${BIN_DIR}..."

    # Ensure target directory exists
    if [[ ! -d "$BIN_DIR" ]]; then
        if (( IS_TERMUX )); then
            mkdir -p "$BIN_DIR"
        else
            ${SUDO} mkdir -p "$BIN_DIR"
        fi
    fi

    # Install binary
    if (( IS_TERMUX )); then
        install -m 0755 "$SOURCE_SCRIPT" "${BIN_DIR}/${APP_NAME}"
        ln -sf "${BIN_DIR}/${APP_NAME}" "${BIN_DIR}/${SHORT_NAME}"
    else
        ${SUDO} install -m 0755 "$SOURCE_SCRIPT" "${BIN_DIR}/${APP_NAME}"
        ${SUDO} ln -sf "${BIN_DIR}/${APP_NAME}" "${BIN_DIR}/${SHORT_NAME}"
    fi

    log_info "Created executable: ${BIN_DIR}/${APP_NAME}"
    log_info "Created alias symlink: ${BIN_DIR}/${SHORT_NAME}"
}

print_success() {
    echo -e "\n${C_CYAN}${C_BOLD}"
    cat << "EOF"
  ██████╗ ██╗  ██╗ ██████╗       ██████╗ ██████╗  ██████╗ ██╗    ██╗███████╗███████╗██████╗ 
  ██╔══██╗██║ ██╔╝██╔════╝       ██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔════╝██╔══██╗
  ██████╔╝█████╔╝ ██║  ███╗█████╗██████╔╝██████╔╝██║   ██║██║ █╗ ██║███████╗█████╗  ██████╔╝
  ██╔═══╝ ██╔═██╗ ██║   ██║╚════╝██╔══██╗██╔══██╗██║   ██║██║███╗██║╚════██║██╔══╝  ██╔══██╗
  ██║     ██║  ██╗╚██████╔╝      ██████╔╝██║  ██║╚██████╔╝╚███╔███╔╝███████║███████╗██║  ██║
  ╚═╝     ╚═╝  ╚═╝ ╚═════╝       ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${C_RESET}"
    echo -e "${C_GREEN}${C_BOLD}✔ Installation finished successfully!${C_RESET}\n"
    echo -e "You can now launch the package browser from any terminal using:"
    echo -e "  ${C_CYAN}${C_BOLD}pkg-browser${C_RESET}  or simply  ${C_CYAN}${C_BOLD}pkgb${C_RESET}\n"
}

main() {
    echo -e "${C_CYAN}${C_BOLD}Starting ${APP_NAME} Installation...${C_RESET}"
    preflight_checks
    install_application
    print_success
}

main "$@"
