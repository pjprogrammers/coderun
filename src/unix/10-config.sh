# shellcheck shell=bash
# shellcheck disable=SC2034
# =============================================================================
# 10-config.sh - Version, paths, platform detection, and shared state
#
# This module is loaded first. It defines every constant that the rest of the
# runner needs and detects the platform-specific compiler and installer paths.
# =============================================================================

# Keep in sync with the VERSION file. scripts/release.sh updates this line.
CODERUN_VERSION="2.4.1"

# Base URL used by --check-update and --update. Override it for testing or to
# point at a mirror. The runner appends /main or /v<version> to this value.
CODERUN_RAW_BASE="${CODERUN_RAW_BASE:-https://raw.githubusercontent.com/pjprogrammers/coderun}"

# Default installation directory. The installers use the same location.
INSTALL_DIR="$HOME/.local/bin"

# Platform-specific settings. Linux and macOS share this runner; only the
# C/C++ compiler, download path, installer hint, and shell configs differ.
case "$(uname -s 2>/dev/null)" in
    Darwin)
        C_COMPILER="clang"
        CPP_COMPILER="clang++"
        RUNNER_PATH="bin/coderun-mac"
        INSTALLER_HINT="./install-mac.sh"
        CONFIG_FILES=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc")
        ;;
    *)
        C_COMPILER="gcc"
        CPP_COMPILER="g++"
        RUNNER_PATH="bin/coderun"
        INSTALLER_HINT="./install.sh"
        CONFIG_FILES=("$HOME/.bashrc")
        ;;
esac

# Temporary files created by update and version-check operations. The EXIT
# trap makes sure a failed operation never leaves files behind.
TEMP_FILE=""
CHECKSUM_FILE=""
LATEST_VERSION=""

cleanup_temp() {
    if [ -n "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
    if [ -n "$CHECKSUM_FILE" ]; then
        rm -f "$CHECKSUM_FILE"
    fi
}

trap cleanup_temp EXIT

# Set by the -q/--quiet flag. All informational output goes through log_info,
# which honours this flag.
QUIET=0
