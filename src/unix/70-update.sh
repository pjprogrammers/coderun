# shellcheck shell=bash
# =============================================================================
# 70-update.sh - Update, version check, and uninstall support
#
# All network access lives in this module. Updates are verified in three ways
# before the installed runner is replaced:
#   1. The downloaded file must look like a coderun Bash script.
#   2. Its embedded version must match the announced release.
#   3. Its SHA-256 hash must match the published SHA256SUMS entry.
# =============================================================================

# Print the name of an available downloader, or return 1 when neither curl nor
# wget is installed.
choose_downloader() {
    if command -v curl >/dev/null 2>&1; then
        echo "curl"
    elif command -v wget >/dev/null 2>&1; then
        echo "wget"
    else
        return 1
    fi
}

# Download a URL to a destination path. Returns 127 when no downloader exists.
download_file() {
    local url="$1"
    local destination="$2"
    local downloader

    downloader="$(choose_downloader)" || return 127

    if [ "$downloader" = "curl" ]; then
        curl -fsSL "$url" -o "$destination"
    else
        wget -qO "$destination" "$url"
    fi
}

# Print the SHA-256 hash of a file. Returns 1 when no hashing tool is available.
sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        return 1
    fi
}

# Return 0 when version $1 is newer than version $2. Versions are semver-like
# dotted triples; missing components are treated as zero.
version_greater() {
    local left="$1"
    local right="$2"
    local i
    local -a left_parts
    local -a right_parts

    IFS='.' read -r -a left_parts <<< "$left"
    IFS='.' read -r -a right_parts <<< "$right"

    for i in 0 1 2; do
        if [ "$((10#${left_parts[i]:-0}))" -gt "$((10#${right_parts[i]:-0}))" ]; then
            return 0
        fi
        if [ "$((10#${left_parts[i]:-0}))" -lt "$((10#${right_parts[i]:-0}))" ]; then
            return 1
        fi
    done

    return 1
}

# Read the published VERSION file into LATEST_VERSION.
# Sets TEMP_FILE and leaves cleanup to the EXIT trap.
fetch_latest_version() {
    local status

    TEMP_FILE="${TMPDIR:-/tmp}/coderun-version.$$"

    download_file "$CODERUN_RAW_BASE/main/VERSION" "$TEMP_FILE"
    status=$?

    if [ "$status" -eq 127 ]; then
        echo "Error: curl or wget is required to check for updates."
        return 1
    fi

    if [ "$status" -ne 0 ]; then
        echo "Error: could not check for updates."
        return 1
    fi

    LATEST_VERSION="$(tr -d '[:space:]' < "$TEMP_FILE")"

    if ! [[ "$LATEST_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: could not read the latest version."
        return 1
    fi

    return 0
}

# Verify that a downloaded file is a coderun script with the expected version.
verify_downloaded_runner() {
    local path="$1"
    local expected_version="$2"
    local downloaded_version

    if [ "$(head -n 1 "$path")" != "#!/usr/bin/env bash" ]; then
        echo "Error: downloaded file does not look like a valid coderun script."
        return 1
    fi

    downloaded_version="$(sed -n 's/^CODERUN_VERSION="\([0-9][0-9.]*\)"$/\1/p' "$path" | head -n 1)"

    if [ "$downloaded_version" != "$expected_version" ]; then
        echo "Error: downloaded runner version does not match $expected_version."
        return 1
    fi

    return 0
}

# Download SHA256SUMS and compare it with the downloaded runner.
verify_downloaded_checksum() {
    local path="$1"
    local checksums_url="$2"
    local expected
    local actual

    if ! download_file "$checksums_url" "$CHECKSUM_FILE"; then
        echo "Error: could not download SHA256SUMS for $LATEST_VERSION."
        return 1
    fi

    expected="$(awk -v path="$RUNNER_PATH" '$2 == path { print $1; exit }' "$CHECKSUM_FILE")"

    if [ -z "$expected" ]; then
        echo "Error: SHA256SUMS does not contain $RUNNER_PATH."
        return 1
    fi

    actual="$(sha256_file "$path")" || {
        echo "Error: sha256sum or shasum is required to verify updates."
        return 1
    }

    if [ "$(lowercase "$expected")" != "$(lowercase "$actual")" ]; then
        echo "Error: update checksum verification failed."
        return 1
    fi

    return 0
}

# Compare the installed version with the published VERSION file.
check_update() {
    echo "Current version: $CODERUN_VERSION"
    echo "Checking for updates..."

    fetch_latest_version || exit 1

    echo "Latest version: $LATEST_VERSION"

    if version_greater "$LATEST_VERSION" "$CODERUN_VERSION"; then
        echo "A new version is available. Run 'coderun --update' to install it."
        exit 1
    fi

    echo "coderun is up to date."
    exit 0
}

# Download, verify, and install the latest runner.
update_coderun() {
    local target="$INSTALL_DIR/coderun"
    local status
    local runner_url
    local checksums_url

    if [ ! -f "$target" ]; then
        echo "Error: coderun is not installed at $target."
        echo "Run $INSTALLER_HINT from the repository first."
        exit 1
    fi

    echo "Current version: $CODERUN_VERSION"
    echo "Checking for updates..."

    fetch_latest_version || exit 1

    echo "Latest version: $LATEST_VERSION"

    if ! version_greater "$LATEST_VERSION" "$CODERUN_VERSION"; then
        rm -f "$TEMP_FILE"
        TEMP_FILE=""
        echo "coderun is up to date ($CODERUN_VERSION)."
        exit 0
    fi

    rm -f "$TEMP_FILE"
    TEMP_FILE="$target.tmp.$$"
    CHECKSUM_FILE="${TMPDIR:-/tmp}/coderun-checksums.$$"

    runner_url="$CODERUN_RAW_BASE/v$LATEST_VERSION/$RUNNER_PATH"
    checksums_url="$CODERUN_RAW_BASE/v$LATEST_VERSION/SHA256SUMS"

    echo "Updating coderun to $LATEST_VERSION..."

    download_file "$runner_url" "$TEMP_FILE"
    status=$?

    if [ "$status" -eq 127 ]; then
        echo "Error: curl or wget is required to update coderun."
        exit 1
    fi

    if [ "$status" -ne 0 ]; then
        echo "Error: update download failed."
        exit 1
    fi

    verify_downloaded_runner "$TEMP_FILE" "$LATEST_VERSION" || exit 1
    verify_downloaded_checksum "$TEMP_FILE" "$checksums_url" || exit 1

    if ! chmod 755 "$TEMP_FILE" || ! mv "$TEMP_FILE" "$target"; then
        echo "Error: could not replace $target."
        exit 1
    fi

    rm -f "$CHECKSUM_FILE"
    CHECKSUM_FILE=""
    TEMP_FILE=""

    echo "coderun updated successfully to $LATEST_VERSION."
}

# Remove the coderun PATH line from one shell configuration file.
remove_path_entry() {
    local config="$1"
    local line='export PATH="$HOME/.local/bin:$PATH"'
    local temp="$config.coderun.$$"

    if [ ! -f "$config" ]; then
        return 0
    fi

    if grep -qF "$line" "$config" 2>/dev/null; then
        grep -vF "$line" "$config" > "$temp" 2>/dev/null || true
        cat "$temp" > "$config"
        rm -f "$temp"
        echo "Removed coderun PATH entry from $config"
    fi
}

# Remove the installed runner and clean up PATH when the install directory is
# left empty.
uninstall_coderun() {
    local target="$INSTALL_DIR/coderun"
    local removed=0
    local install_dir_empty=0
    local config

    if [ -f "$target" ]; then
        rm -f "$target"
        echo "Removed $target"
        removed=1
    fi

    if [ -d "$INSTALL_DIR" ]; then
        if [ -z "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
            install_dir_empty=1
        fi
    else
        install_dir_empty=1
    fi

    if [ "$install_dir_empty" -eq 1 ]; then
        for config in "${CONFIG_FILES[@]}"; do
            remove_path_entry "$config"
        done

        rmdir "$INSTALL_DIR" 2>/dev/null || true
    else
        echo "Kept $INSTALL_DIR in PATH because it contains other files."
    fi

    if [ "$removed" -eq 0 ]; then
        echo "coderun was not installed at $target."
    else
        echo "coderun uninstalled successfully."
        echo "Open a new terminal to finish."
    fi
}
