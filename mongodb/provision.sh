#!/usr/bin/env bash
# shellcheck shell=bash
# Mongodb
set -e

export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Known GPG key fingerprints for verification
declare -A MONGODB_KEY_FINGERPRINTS=(
    ["3.4"]="0C49F3730359A14518585931BC711F9BA15703C6"
    ["4.4"]="20691EEC35216C63CAF66CE1656408E390CFB1F5"
    ["8.0"]="4B0752C1BCA238C0B4EE14DC41DE058A4E7DCA05"
)

# Get MongoDB version configuration based on Ubuntu codename
# Returns: MONGO_VERSION MONGO_CODENAME MONGO_SHELL
get_mongodb_config() {
    local codename="$1"
    case "$codename" in
        trusty)
            # Ubuntu 14.04 - MongoDB 3.4
            echo "3.4 trusty mongo"
            ;;
        xenial|bionic|focal|jammy)
            # Ubuntu 16.04-22.04 - MongoDB 4.4
            echo "4.4 ${codename} mongo"
            ;;
        noble)
            # Ubuntu 24.04 - MongoDB 8.0 (first version with official Noble support)
            echo "8.0 noble mongosh"
            ;;
        *)
            # Unknown codename - default to MongoDB 8.0 with noble repos
            echo " * Warning: Unknown Ubuntu codename '${codename}', defaulting to MongoDB 8.0" >&2
            echo "8.0 noble mongosh"
            ;;
    esac
}

install_mongodb_php() {
    # Start with known PHP versions
    local known_versions=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3" "8.4" "8.5")

    # Also scan /etc/php/ for any installed versions not in our list
    if [[ -d /etc/php ]]; then
        for dir in /etc/php/*/; do
            if [[ -d "$dir" ]]; then
                local ver
                ver=$(basename "$dir")
                # Check if it looks like a version number and isn't already in our list
                if [[ "$ver" =~ ^[0-9]+\.[0-9]+$ ]]; then
                    local found=0
                    for known in "${known_versions[@]}"; do
                        if [[ "$known" == "$ver" ]]; then
                            found=1
                            break
                        fi
                    done
                    if [[ $found -eq 0 ]]; then
                        echo " * Discovered additional PHP version: ${ver}"
                        known_versions+=("$ver")
                    fi
                fi
            fi
        done
    fi

    for version in "${known_versions[@]}"
    do
        if [[ $(command -v "php$version") ]]; then
            echo " * Checking MongoDB for PHP ${version}"
            if [ -e "/etc/php/${version}/mods-available/mongodb.ini" ]; then
                echo " * MongoDB PHP v${version} extension is already installed"
            else
                echo " * Installing MongoDB for PHP ${version}"
                # Log to file for debugging (/tmp is world-writable so redirect is fine)
                # shellcheck disable=SC2024
                if ! sudo pecl -d php_suffix="$version" install mongodb > "/tmp/pecl-mongodb-${version}.log" 2>&1; then
                    echo " * Warning: PECL install failed for PHP ${version}, check /tmp/pecl-mongodb-${version}.log"
                    continue
                fi
                # do not remove files, only register the packages as not installed so we can install for other php version
                sudo pecl uninstall -r mongodb > /dev/null 2>&1 || true
                cp -f "${DIR}/mongodb.ini" "/etc/php/${version}/mods-available/mongodb.ini"
                phpenmod -v "${version}" mongodb
                echo " * Installed PHP v${version} MongoDB driver"
            fi
        fi
    done
}

install_mongodb() {
    echo " * Installing MongoDB"
    local codename
    codename=$(lsb_release --codename | cut -f2)

    # Get version configuration for this Ubuntu release
    # MONGO_SHELL is read for documentation but detected dynamically later
    local MONGO_VERSION MONGO_CODENAME MONGO_SHELL
    read -r MONGO_VERSION MONGO_CODENAME MONGO_SHELL <<< "$(get_mongodb_config "$codename")"
    export MONGO_SHELL  # Suppress shellcheck unused warning, may be useful for debugging
    echo " * Detected Ubuntu ${codename}, will install MongoDB ${MONGO_VERSION}"

    # Clean up old apt sources
    rm -f /etc/apt/sources.list.d/mongodb-org*.list

    # Set up GPG key using modern approach
    local key_file="${DIR}/server-${MONGO_VERSION}.asc"
    local keyring_path="/etc/apt/keyrings/mongodb-server-${MONGO_VERSION}.gpg"

    if [[ ! -f "$key_file" ]]; then
        echo " * Error: GPG key file not found: ${key_file}"
        return 1
    fi

    # Verify GPG key fingerprint if we have it on record
    if [[ -n "${MONGODB_KEY_FINGERPRINTS[$MONGO_VERSION]:-}" ]]; then
        local expected_fingerprint="${MONGODB_KEY_FINGERPRINTS[$MONGO_VERSION]}"
        local actual_fingerprint
        actual_fingerprint=$(gpg --with-fingerprint --with-colons "$key_file" 2>/dev/null | grep -m1 "^fpr:" | cut -d: -f10)
        if [[ "$actual_fingerprint" != "$expected_fingerprint" ]]; then
            echo " * Error: GPG key fingerprint mismatch!"
            echo " *   Expected: ${expected_fingerprint}"
            echo " *   Got: ${actual_fingerprint}"
            return 1
        fi
        echo " * GPG key fingerprint verified: ${expected_fingerprint}"
    fi

    # Create keyrings directory if it doesn't exist
    mkdir -p /etc/apt/keyrings

    # Convert ASCII armored key to binary GPG format
    if ! gpg --dearmor -o "$keyring_path" < "$key_file" 2>/dev/null; then
        # If dearmor fails (key might already be binary), copy directly
        cp "$key_file" "$keyring_path"
    fi
    chmod 644 "$keyring_path"

    # Also add to trusted.gpg.d for older Ubuntu compatibility
    cp "$keyring_path" "/etc/apt/trusted.gpg.d/mongodb-server-${MONGO_VERSION}.gpg"

    # Remove old apt-key entries for MongoDB
    if command -v apt-key &>/dev/null; then
        apt-key del '2069 1EEC 3521 6C63 CAF6  6CE1 6564 08E3 90CF B1F5' 2>/dev/null || true
        apt-key del 'MongoDB 3.4' 2>/dev/null || true
        apt-key del 'MongoDB 4.4' 2>/dev/null || true
        apt-key del 'MongoDB 8.0' 2>/dev/null || true
    fi

    # Add the repository with signed-by pointing to the keyring
    echo "deb [arch=amd64,arm64 signed-by=${keyring_path}] https://repo.mongodb.org/apt/ubuntu ${MONGO_CODENAME}/mongodb-org/${MONGO_VERSION} multiverse" | sudo tee "/etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list"

    echo " * Running apt-get update"
    apt-get -y update
    echo " * Installing apt-get packages"
    local apt_package_install_list=(
        mongodb-org
        re2c
    )
    if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken "${apt_package_install_list[@]}"; then
        echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
        apt-get clean
        return 1
    fi
}

setup_mongodb_indexes() {
    echo " * Setting up MongoDB indexes for XHGui (with 30-day TTL)"

    # Detect which MongoDB shell is available
    local mongo_shell=""
    if command -v mongosh &>/dev/null; then
        mongo_shell="mongosh"
    elif command -v mongo &>/dev/null; then
        mongo_shell="mongo"
    else
        echo " * Warning: No MongoDB shell found, skipping index setup"
        return 0
    fi

    # Use createIndex (ensureIndex is deprecated in newer MongoDB versions)
    # These may fail if xhprof database doesn't exist yet, that's OK
    $mongo_shell xhprof --eval 'db.collection.createIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval "db.collection.createIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval "db.collection.createIndex( { 'profile.main().wt' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval "db.collection.createIndex( { 'profile.main().mu' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval "db.collection.createIndex( { 'profile.main().cpu' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval "db.collection.createIndex( { 'meta.url' : 1 } )" > /dev/null 2>&1 || true
}

restart_mongod() {
    # Check if mongod is already running
    if pgrep -x mongod > /dev/null 2>&1; then
        echo " * MongoDB is already running"
        return 0
    fi

    echo " * Starting MongoDB service"
    local started=0

    # Try systemd first
    if pidof systemd > /dev/null 2>&1; then
        echo " * Using systemd to start MongoDB"
        if systemctl start mongod.service 2>/dev/null; then
            started=1
        fi
    fi

    # Try service command (SysVinit/Upstart) if systemd didn't work
    if [[ $started -eq 0 ]] && command -v service > /dev/null 2>&1; then
        echo " * Using service command to start MongoDB"
        if service mongod start 2>/dev/null; then
            started=1
        fi
    fi

    # Fall back to starting mongod directly (common in Docker)
    if [[ $started -eq 0 ]]; then
        echo " * Starting mongod directly"
        if mongod --config /etc/mongod.conf --fork 2>/dev/null; then
            started=1
        fi
    fi

    # Give it a moment to start
    sleep 2

    # Verify mongod is running
    if pgrep -x mongod > /dev/null 2>&1; then
        echo " * MongoDB started successfully"
    else
        echo " * Warning: MongoDB may not have started correctly"
        echo " * Check logs at /var/log/mongodb/mongod.log"
        return 1
    fi
}

# Create the log and data directories if they don't exist already
mkdir -p /var/log/mongodb
mkdir -p /data/db

echo " * Making sure mongodb service is enabled"

# Check for either mongo or mongosh shell (MongoDB 8.0+ uses mongosh)
if [[ ! $(command -v mongo) ]] && [[ ! $(command -v mongosh) ]]; then
    install_mongodb
fi
install_mongodb_php

# make sure mongo can actually write to the log folder
chown mongodb /var/log/mongodb

# Enable mongod service to start on boot
if pidof systemd > /dev/null 2>&1; then
    echo " * Enabling mongod service (systemd)"
    systemctl enable mongod.service
elif command -v update-rc.d > /dev/null 2>&1; then
    echo " * Enabling mongod service (SysVinit)"
    update-rc.d mongod defaults > /dev/null 2>&1 || true
fi

restart_mongod

# Set up indexes after service is running
setup_mongodb_indexes

echo " * MongoDB provisioning complete"
