#!/usr/bin/env bash

VVV_CONFIG=/vagrant/vvv-custom.yml
if [[ -f /vagrant/config.yml ]]; then
	VVV_CONFIG=/vagrant/config.yml
fi

codename=$(lsb_release --codename | cut -f2)
CERTIFICATES_DIR="/srv/certificates"
if [[ $codename == "trusty" ]]; then # VVV 2 uses Ubuntu 14 LTS trusty
    echo " ! Unsupported Ubuntu 14 detected! Switching certificate folder, please upgrade to VVV 3+"
    CERTIFICATES_DIR="/vagrant/certificates"
fi

CA_DIR="${CERTIFICATES_DIR}/ca"

if [ ! -d "${CA_DIR}" ];then
    echo " * Setting up VVV Certificate Authority"
    mkdir -p "${CA_DIR}"

    openssl genrsa \
        -out "${CA_DIR}/ca.key" \
        2048 &>/dev/null

    openssl req \
        -x509 -new \
        -nodes \
        -key "${CA_DIR}/ca.key" \
        -sha256 \
        -days 3650 \
        -out "${CA_DIR}/ca.crt" \
        -subj "/CN=VVV INTERNAL CA" &>/dev/null
fi

mkdir -p /usr/share/ca-certificates/vvv
if [[ ! -f /usr/share/ca-certificates/vvv/ca.crt ]]; then
    echo " * Adding root certificate to the VM"
    cp -f "${CA_DIR}/ca.crt" /usr/share/ca-certificates/vvv/ca.crt
    echo " * Updating loaded VM certificates"
    update-ca-certificates --fresh
fi

echo " * Setting up default Certificate for vvv.test and vvv.local"

DEFAULT_CERT_DIR="${CERTIFICATES_DIR}/default"

rm -rf "${DEFAULT_CERT_DIR}"
mkdir -p "${DEFAULT_CERT_DIR}"

cat << EOF > "${DEFAULT_CERT_DIR}/openssl.conf"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vvv.test
DNS.2 = *.vvv.test
DNS.3 = vvv.local
DNS.4 = *.vvv.local
DNS.5 = vvv
DNS.6 = *.vvv
EOF

openssl genrsa \
    -out "${DEFAULT_CERT_DIR}/dev.key" \
    2048 &>/dev/null

openssl req \
    -new \
    -key "${DEFAULT_CERT_DIR}/dev.key" \
    -out "${DEFAULT_CERT_DIR}/dev.csr" \
    -subj "/CN=vvv.test"  &>/dev/null

openssl x509 \
    -req \
    -in "${DEFAULT_CERT_DIR}/dev.csr" \
    -CA "${CA_DIR}/ca.crt" \
    -CAkey "${CA_DIR}/ca.key" \
    -CAcreateserial \
    -out "${DEFAULT_CERT_DIR}/dev.crt" \
    -days 3650 \
    -sha256 \
    -extfile "${DEFAULT_CERT_DIR}/openssl.conf"  &>/dev/null

echo " * Symlinking default server certificate and key"

rm -rf /etc/nginx/server-2.1.0.crt
rm -rf /etc/nginx/server-2.1.0.key

echo " * Symlinking ${DEFAULT_CERT_DIR}/dev.crt to /etc/nginx/server-2.1.0.crt"
ln -s "${DEFAULT_CERT_DIR}/dev.crt" /etc/nginx/server-2.1.0.crt

echo " * Symlinking ${DEFAULT_CERT_DIR}/dev.key to /etc/nginx/server-2.1.0.key"
ln -s "${DEFAULT_CERT_DIR}/dev.key" /etc/nginx/server-2.1.0.key

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

echo " * Generating Site certificates"
for SITE in $(get_sites); do
    echo " * Generating certificates for the '${SITE}' hosts"
    SITE_ESCAPED="${SITE//./\\.}"
    COMMON_NAME=$(get_host "${SITE_ESCAPED}")
    HOSTS=$(get_hosts "${SITE_ESCAPED}")
    SITE_CERT_DIR="${CERTIFICATES_DIR}/${SITE}"

    rm -rf "${SITE_CERT_DIR}"
    mkdir -p "${SITE_CERT_DIR}"

    cat << EOF > "${SITE_CERT_DIR}/openssl.conf"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF
    I=0
    for DOMAIN in ${HOSTS}; do
        ((I++))
        echo "DNS.${I} = ${DOMAIN}" >> "${SITE_CERT_DIR}/openssl.conf"
        ((I++))
        echo "DNS.${I} = *.${DOMAIN}" >> "${SITE_CERT_DIR}/openssl.conf"
    done

    openssl genrsa \
        -out "${SITE_CERT_DIR}/dev.key" \
        2048 &>/dev/null

    openssl req \
        -new \
        -key "${SITE_CERT_DIR}/dev.key" \
        -out "${SITE_CERT_DIR}/dev.csr" \
        -subj "/CN=${COMMON_NAME}" &>/dev/null

    openssl x509 \
        -req \
        -in "${SITE_CERT_DIR}/dev.csr" \
        -CA "${CA_DIR}/ca.crt" \
        -CAkey "${CA_DIR}/ca.key" \
        -CAcreateserial \
        -out "${SITE_CERT_DIR}/dev.crt" \
        -days 3650 \
        -sha256 \
        -extfile "${SITE_CERT_DIR}/openssl.conf" &>/dev/null
done


echo " * Finished generating TLS certificates"
