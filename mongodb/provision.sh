#!/usr/bin/env bash
# Mongodb
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
                local ver=$(basename "$dir")
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
        if [[ $(command -v php$version) ]]; then
            echo " * Checking MongoDB for PHP ${version}"
            if [ -e "/etc/php/${version}/mods-available/mongodb.ini" ]; then
                echo " * MongoDB PHP v${version} extension is already installed"
            else
                echo " * Installing MongoDB for PHP ${version}"
                sudo pecl -d php_suffix="$version" install mongodb > /dev/null 2>&1
                # do not remove files, only register the packages as not installed so we can install for other php version
                sudo pecl uninstall -r mongodb > /dev/null 2>&1
                cp -f "${DIR}/mongodb.ini" "/etc/php/${version}/mods-available/mongodb.ini"
                phpenmod -v "${version}" mongodb
                echo " * Installed PHP v${version} MongoDB driver"
            fi
        fi
    done
}

install_mongodb() {
    echo " * Installing MongoDB"
    codename=$(lsb_release --codename | cut -f2)

    # Get version configuration for this Ubuntu release
    read -r MONGO_VERSION MONGO_CODENAME MONGO_SHELL <<< "$(get_mongodb_config "$codename")"
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

    # Create keyrings directory if it doesn't exist
    mkdir -p /etc/apt/keyrings

    # Convert ASCII armored key to binary GPG format
    gpg --dearmor -o "$keyring_path" < "$key_file" 2>/dev/null || {
        # If dearmor fails (key might already be binary), copy directly
        cp "$key_file" "$keyring_path"
    }
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
    echo "deb [arch=amd64,arm64 signed-by=${keyring_path}] https://repo.mongodb.org/apt/ubuntu ${MONGO_CODENAME}/mongodb-org/${MONGO_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list

    echo " * Running apt-get update"
    apt-get -y update
    echo " * Installing apt-get packages"
    apt_package_install_list=(
        mongodb-org
        re2c
    )
    if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${apt_package_install_list[@]}; then
        echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
        apt-get clean
        return 1
    fi
}

cleanup_mongodb_entries() {
    echo " * Auto-removing mongoDB records older than 2592000 seconds (30 days)"

    # Detect which MongoDB shell is available
    local mongo_shell=""
    if command -v mongosh &>/dev/null; then
        mongo_shell="mongosh"
    elif command -v mongo &>/dev/null; then
        mongo_shell="mongo"
    else
        echo " * Warning: No MongoDB shell found, skipping cleanup"
        return 0
    fi

    # Use createIndex (ensureIndex is deprecated in newer MongoDB versions)
    # Add || true to prevent failures if xhprof database doesn't exist yet
    $mongo_shell xhprof --eval 'db.collection.createIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1 || true
    # indexes
    $mongo_shell xhprof --eval  "db.collection.createIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval  "db.collection.createIndex( { 'profile.main().wt' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval  "db.collection.createIndex( { 'profile.main().mu' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval  "db.collection.createIndex( { 'profile.main().cpu' : -1 } )" > /dev/null 2>&1 || true
    $mongo_shell xhprof --eval  "db.collection.createIndex( { 'meta.url' : 1 } )" > /dev/null 2>&1 || true
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
cleanup_mongodb_entries

# make sure mongo can actually write to the log folder
chown mongodb /var/log/mongodb

echo " * Restarting mongod"
systemctl enable mongod.service
systemctl start mongod.service

echo " * MongoDB provisioning complete"
