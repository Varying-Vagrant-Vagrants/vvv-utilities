#!/usr/bin/env bash

VVV_CONFIG=/vagrant/vvv-config.yml
if [[ -f /vagrant/vvv-custom.yml ]]; then
	VVV_CONFIG=/vagrant/vvv-custom.yml
fi

CERTIFICATES_DIR="/vagrant/certificates"
CA_DIR="${CERTIFICATES_DIR}/ca"

if [ ! -d ${CA_DIR} ];then
    mkdir -p ${CA_DIR}

    openssl genrsa \
        -out ${CA_DIR}/ca.key \
        2048 &>/dev/null

    openssl req \
        -x509 -new \
        -nodes \
        -key ${CA_DIR}/ca.key \
        -sha256 \
        -days 3650 \
        -out ${CA_DIR}/ca.crt \
        -subj "/CN=VVV INTERNAL CA" &>/dev/null
fi

CERT_DIR="${CERTIFICATES_DIR}/default"

rm -rf "${CERT_DIR}"
mkdir -p "${CERT_DIR}"

cat << EOF > ${CERT_DIR}/openssl.conf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vvv.test
DNS.2 = *.vvv.test
DNS.3 = vvv.dev
DNS.4 = *.vvv.dev
DNS.5 = vvv.local
DNS.6 = *.vvv.local
EOF

openssl genrsa \
    -out ${CERT_DIR}/dev.key \
    2048 &>/dev/null

openssl req \
    -new \
    -key ${CERT_DIR}/dev.key \
    -out ${CERT_DIR}/dev.csr \
    -subj "/CN=vvv.test"  &>/dev/null

openssl x509 \
    -req \
    -in ${CERT_DIR}/dev.csr \
    -CA ${CA_DIR}/ca.crt \
    -CAkey ${CA_DIR}/ca.key \
    -CAcreateserial \
    -out ${CERT_DIR}/dev.crt \
    -days 3650 \
    -sha256 \
    -extfile ${CERT_DIR}/openssl.conf  &>/dev/null

rm -rf /etc/nginx/server-2.1.0.crt
rm -rf /etc/nginx/server-2.1.0.key

ln -s ${CERT_DIR}/dev.crt /etc/nginx/server-2.1.0.crt
ln -s ${CERT_DIR}/dev.key /etc/nginx/server-2.1.0.key

get_sites() {
    local value=`cat ${VVV_CONFIG} | shyaml keys sites 2> /dev/null`
    echo ${value:-$@}
}

get_host() {
    local value=`cat ${VVV_CONFIG} | shyaml get-value sites.${1}.hosts.0 2> /dev/null`
    echo ${value:-$@}
}

get_hosts() {
    local value=`cat ${VVV_CONFIG} | shyaml get-values sites.${1}.hosts 2> /dev/null`
    echo ${value:-$@}
}

for SITE in `get_sites`; do
    SITE_ESCAPED=`echo ${SITE} | sed 's/\./\\\\./g'`
    COMMON_NAME=`get_host ${SITE_ESCAPED}`
    HOSTS=`get_hosts ${SITE_ESCAPED}`
    CERT_DIR="${CERTIFICATES_DIR}/${SITE}"

    rm -rf "${CERT_DIR}"
    mkdir -p "${CERT_DIR}"

    cat << EOF > ${CERT_DIR}/openssl.conf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF
    I=0
    for DOMAIN in ${HOSTS}; do
        ((I++))
        echo DNS.${I} = ${DOMAIN} >> ${CERT_DIR}/openssl.conf
        ((I++))
        echo DNS.${I} = *.${DOMAIN} >> ${CERT_DIR}/openssl.conf
    done

    openssl genrsa \
        -out ${CERT_DIR}/dev.key \
        2048 &>/dev/null

    openssl req \
        -new \
        -key ${CERT_DIR}/dev.key \
        -out ${CERT_DIR}/dev.csr \
        -subj "/CN=${COMMON_NAME}" &>/dev/null

    openssl x509 \
        -req \
        -in ${CERT_DIR}/dev.csr \
        -CA ${CA_DIR}/ca.crt \
        -CAkey ${CA_DIR}/ca.key \
        -CAcreateserial \
        -out ${CERT_DIR}/dev.crt \
        -days 3650 \
        -sha256 \
        -extfile ${CERT_DIR}/openssl.conf &>/dev/null
done
