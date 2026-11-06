#!/usr/bin/env bash

# Install external dependencies for Neovim Shell language support.
#
# Usage:
#   ./scripts/install/core/bash-shell.sh
#
# Required tools:
#   - bash
#   - bash-language-server
#   - shellcheck
#   - shfmt
#
# Installation:
#   - bash-language-server: npm
#   - shellcheck: system package manager
#   - shfmt: system package manager
#
# Supported platforms:
#   - macOS: Homebrew
#   - Debian/Ubuntu: APT
#   - Fedora/RHEL: DNF
#   - Arch Linux: Pacman
#   - openSUSE: Zypper
#   - Alpine Linux: APK
#
# Windows:
#   Use the PowerShell installer instead.
#
# Bash is checked but is not installed by this script.

set -Eeuo pipefail

readonly SCRIPT_NAME="bash-shell"
readonly REQUIRED_NPM_PACKAGE="bash-language-server"

failures=0

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

info() {
    printf '[INFO] %s\n' "$*"
}

success() {
    printf '[PASS] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

detect_platform() {
    case "$(uname -s)" in
    Darwin)
        printf 'macos\n'
        ;;
    Linux)
        printf 'linux\n'
        ;;
    MINGW* | MSYS* | CYGWIN*)
        printf 'windows\n'
        ;;
    *)
        printf 'unsupported\n'
        ;;
    esac
}

readonly PLATFORM="$(detect_platform)"

# ---------------------------------------------------------------------------
# Privilege handling
# ---------------------------------------------------------------------------

run_privileged() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    elif command_exists sudo; then
        sudo "$@"
    else
        error "Root privileges or sudo are required to install system packages."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Bash runtime
# ---------------------------------------------------------------------------

check_bash() {
    info "Checking Bash runtime..."

    if command_exists bash; then
        bash --version | head -n 1
        success "Bash runtime is available."
    else
        warn "Bash was not found on PATH."
        warn "Install Bash separately before using the Shell execution workflow."
    fi
}

# ---------------------------------------------------------------------------
# Package manager detection
# ---------------------------------------------------------------------------

detect_package_manager() {
    if [[ "$PLATFORM" == "macos" ]]; then
        command_exists brew && {
            printf 'brew\n'
            return 0
        }
    fi

    if [[ "$PLATFORM" == "linux" ]]; then
        for manager in apt-get dnf pacman zypper apk; do
            if command_exists "$manager"; then
                printf '%s\n' "$manager"
                return 0
            fi
        done
    fi

    return 1
}

# ---------------------------------------------------------------------------
# System formatter and linter installation
# ---------------------------------------------------------------------------

install_system_tools() {
    local manager

    if command_exists shellcheck && command_exists shfmt; then
        success "ShellCheck and shfmt are already installed."
        return 0
    fi

    if ! manager="$(detect_package_manager)"; then
        error "No supported package manager was found."
        error "Install ShellCheck and shfmt manually."
        return 1
    fi

    info "Installing ShellCheck and shfmt using ${manager}..."

    case "$manager" in
    brew)
        brew install shellcheck shfmt
        ;;
    apt-get)
        run_privileged apt-get update
        run_privileged apt-get install -y shellcheck shfmt
        ;;
    dnf)
        run_privileged dnf install -y ShellCheck shfmt
        ;;
    pacman)
        run_privileged pacman -S --needed --noconfirm shellcheck shfmt
        ;;
    zypper)
        run_privileged zypper --non-interactive install ShellCheck shfmt
        ;;
    apk)
        run_privileged apk add shellcheck shfmt
        ;;
    *)
        error "Unsupported package manager: ${manager}"
        return 1
        ;;
    esac

    success "System Shell tools installation completed."
}

# ---------------------------------------------------------------------------
# Bash Language Server installation
# ---------------------------------------------------------------------------

install_bash_language_server() {
    if command_exists bash-language-server; then
        success "Bash Language Server is already installed."
        return 0
    fi

    if ! command_exists npm; then
        error "npm was not found."
        error "Install Node.js and npm before installing Bash Language Server."
        return 1
    fi

    info "Installing Bash Language Server through npm..."

    npm install --global "$REQUIRED_NPM_PACKAGE"

    success "Bash Language Server installation completed."
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

verify_tool() {
    local tool="$1"

    if command_exists "$tool"; then
        success "${tool} is available at $(command -v "$tool")."
        return 0
    fi

    error "${tool} is not available on PATH."
    return 1
}

verify_installation() {
    local tool

    info "Verifying Shell dependencies..."

    for tool in bash bash-language-server shellcheck shfmt; do
        if ! verify_tool "$tool"; then
            ((failures += 1))
        fi
    done

    if command_exists bash; then
        info "Bash version:"
        bash --version | head -n 1
    fi

    if command_exists bash-language-server; then
        info "Bash Language Server version:"
        bash-language-server --version
    fi

    if command_exists shellcheck; then
        info "ShellCheck version:"
        shellcheck --version | grep -m 1 'version:'
    fi

    if command_exists shfmt; then
        info "shfmt version:"
        shfmt --version
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    printf '\n%s: Shell dependency installation\n\n' "$SCRIPT_NAME"

    case "$PLATFORM" in
    windows)
        error "Run the Windows PowerShell installer instead."
        error "Do not use this script under Git Bash on Windows."
        exit 1
        ;;
    unsupported)
        error "Unsupported operating system."
        exit 1
        ;;
    esac

    check_bash

    if ! install_system_tools; then
        ((failures += 1))
    fi

    if ! install_bash_language_server; then
        ((failures += 1))
    fi

    printf '\n'
    verify_installation

    printf '\n'

    if ((failures > 0)); then
        error "Installation completed with ${failures} issue(s)."
        exit 1
    fi

    success "All Shell dependencies are available."
}

main "$@"
