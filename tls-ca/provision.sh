#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

VVV_CONFIG=/vagrant/vvv-custom.yml
if [[ -f /vagrant/config.yml ]]; then
	VVV_CONFIG=/vagrant/config.yml
fi

codename=$(lsb_release --codename | cut -f2)
CERTIFICATES_DIR="/srv/certificates"
if [[ $codename == "trusty" ]]; then # VVV 2 uses Ubuntu 14 LTS trusty
    echo " ! WARNING: Unsupported Ubuntu 14 detected! Switching certificate folder, please upgrade to VVV 3+"
    CERTIFICATES_DIR="/vagrant/certificates"
fi

DEFAULT_CERT_DIR="${CERTIFICATES_DIR}/default"
CA_DIR="${CERTIFICATES_DIR}/ca"
ROOT_CA_DAYS=397 # MacOS/Apple won't accept Root CA's that last longer than this
SITE_CERTIFICATE_DAYS=200

# Fix a bug that happens if you run the provisioner sometimes
if [[ ! -e ~/.rnd ]]; then
    echo " * Generating Random Number for cert generation..."
    openssl rand -out ~/.rnd -hex 256 2>&1
fi

get_sites() {
    local value=$(shyaml keys sites 2> /dev/null < ${VVV_CONFIG})
    echo "${value:-$@}"
}

get_host() {
    local value=$(shyaml get-value "sites.${1}.hosts.0" 2> /dev/null < ${VVV_CONFIG})
    echo "${value:-$@}"
}

get_hosts() {
    local value=$(shyaml get-values "sites.${1}.hosts" 2> /dev/null < ${VVV_CONFIG})
    echo "${value:-$@}"
}

install_root_certificate() {
    mkdir -p /usr/share/ca-certificates/vvv
    if [[ ! -f /usr/share/ca-certificates/vvv/ca.crt ]]; then
        echo " * Adding root certificate to the VM"
        cp -f "${CA_DIR}/ca.crt" /usr/share/ca-certificates/vvv/ca.crt
        echo " * Updating loaded VM certificates"
        update-ca-certificates --fresh
    fi
}

create_root_certificate() {

    if [ ! -d "${CA_DIR}" ]; then
        echo " * Setting up VVV Certificate Authority"
        mkdir -p "${CA_DIR}"
    fi

    if [[ ! -e "${DEFAULT_CERT_DIR}/dev.key" ]]; then
        echo " * Generating key root certificate"
        openssl genrsa \
            -out "${CA_DIR}/ca.key" \
            2048 &>/dev/null
    fi

    openssl req \
        -x509 -new \
        -nodes \
        -key "${CA_DIR}/ca.key" \
        -sha256 \
        -days $ROOT_CA_DAYS \
        -config "${DIR}/openssl-ca.conf" \
        -out "${CA_DIR}/ca.crt"
}

setup_default_certificate_key_csr() {
    echo " * Generating key and CSR for vvv.test"

    if [[ ! -e "${DEFAULT_CERT_DIR}/dev.key" ]]; then
        echo " * Generating key for:             'vvv.test'"
        openssl genrsa \
            -out "${DEFAULT_CERT_DIR}/dev.key" \
            2048 &>/dev/null
    fi

    if [[ ! -e "${DEFAULT_CERT_DIR}/dev.csr" ]]; then
        echo " * Generating CSR for:             'vvv.test'"
        openssl req \
            -new \
            -key "${DEFAULT_CERT_DIR}/dev.key" \
            -out "${DEFAULT_CERT_DIR}/dev.csr" \
            -subj "/CN=vvv.test/C=GB/ST=Test Province/L=Test Locality/O=VVV/OU=VVV" &>/dev/null
    fi
}

create_default_certificate() {
    echo " * Setting up default Certificate for vvv.test and vvv.local"

    mkdir -p "${DEFAULT_CERT_DIR}"

    setup_default_certificate_key_csr

    echo " * Removing and renewing the default certificate"

    rm "${DEFAULT_CERT_DIR}/dev.crt"

    openssl x509 \
        -req \
        -in "${DEFAULT_CERT_DIR}/dev.csr" \
        -CA "${CA_DIR}/ca.crt" \
        -CAkey "${CA_DIR}/ca.key" \
        -CAcreateserial \
        -out "${DEFAULT_CERT_DIR}/dev.crt" \
        -days $SITE_CERTIFICATE_DAYS \
        -sha256 \
        -extfile "${DIR}/openssl-default-cert.conf" &>/dev/null
}

install_default_certificate() {
    echo " * Symlinking default server certificate and key"

    rm -rf /etc/nginx/server-2.1.0.crt
    rm -rf /etc/nginx/server-2.1.0.key

    echo " * Symlinking ${DEFAULT_CERT_DIR}/dev.crt to /etc/nginx/server-2.1.0.crt"
    ln -s "${DEFAULT_CERT_DIR}/dev.crt" /etc/nginx/server-2.1.0.crt

    echo " * Symlinking ${DEFAULT_CERT_DIR}/dev.key to /etc/nginx/server-2.1.0.key"
    ln -s "${DEFAULT_CERT_DIR}/dev.key" /etc/nginx/server-2.1.0.key
}

setup_site_key_csr() {
    SITE=${1}
    SITE_ESCAPED="${SITE//./\\.}"
    COMMON_NAME=$(get_host "${SITE_ESCAPED}")
    SITE_CERT_DIR="${CERTIFICATES_DIR}/${SITE}"

    mkdir -p "${SITE_CERT_DIR}"

    if [[ ! -e "${SITE_CERT_DIR}/dev.key" ]]; then
        echo " * Generating key for:             '${SITE}'"
        openssl genrsa \
            -out "${SITE_CERT_DIR}/dev.key" \
            2048 &>/dev/null
    fi
    if [[ ! -e "${SITE_CERT_DIR}/dev.csr" ]]; then
        echo " * Generating CSR for:             '${SITE}'"
        openssl req \
            -new \
            -key "${SITE_CERT_DIR}/dev.key" \
            -out "${SITE_CERT_DIR}/dev.csr" \
            -subj "/CN=${COMMON_NAME//\\/}/C=GB/ST=Test Province/L=Test Locality/O=VVV/OU=VVV" &>/dev/null
    fi
}

regenerate_site_certificate() {
    SITE=${1}
    SITE_CERT_DIR="${CERTIFICATES_DIR}/${SITE}"
    SITE_ESCAPED="${SITE//./\\.}"
    COMMON_NAME=$(get_host "${SITE_ESCAPED}")

    setup_site_key_csr $SITE


    echo " * Generating new certificate for: '${SITE}'"
    rm -f "${SITE_CERT_DIR}/dev.crt"

    # Copy over the site conf stub then append the domains
    cp -f "${DIR}/openssl-site-stub.conf" "${SITE_CERT_DIR}/openssl.conf"

    HOSTS=$(get_hosts "${SITE_ESCAPED}")
    I=0
    for DOMAIN in ${HOSTS}; do
        ((I++))
        echo "DNS.${I} = ${DOMAIN//\\/}" >> "${SITE_CERT_DIR}/openssl.conf"
        ((I++))
        echo "DNS.${I} = *.${DOMAIN//\\/}" >> "${SITE_CERT_DIR}/openssl.conf"
    done

    openssl x509 \
        -req \
        -in "${SITE_CERT_DIR}/dev.csr" \
        -CA "${CA_DIR}/ca.crt" \
        -CAkey "${CA_DIR}/ca.key" \
        -CAcreateserial \
        -out "${SITE_CERT_DIR}/dev.crt" \
        -days 200 \
        -sha256 \
        -extfile "${SITE_CERT_DIR}/openssl.conf" &>/dev/null
}

process_site_certificates() {
    echo " * Generating site certificates"
    for SITE in $(get_sites); do
        regenerate_site_certificate $SITE
    done
    echo " * Finished generating site certificates"
}

create_root_certificate
install_root_certificate
create_default_certificate
install_default_certificate
process_site_certificates

echo " * Finished generating TLS certificates"
