#!/usr/bin/env bash

# This script is used to issue certificates for the tests.

COUNTRY="DE"
STATE="Lower Saxony"
CITY="Braunschweig"
ORG="PTB"
ORG_UNIT="1.24"
EMAIL="example@ptb.de"
DAYS=365

echo "Creating CA key..."
openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days $DAYS \
    -extensions v3_ca -addext "keyUsage = keyCertSign" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=ca/emailAddress=$EMAIL" \
    -keyout ca.key -out ca.pem

echo "Creating cert..."
openssl req -nodes -newkey rsa:2048 -sha256 \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=cert/emailAddress=$EMAIL" \
    -extensions v3_req -addext "keyUsage = digitalSignature" \
    -addext "extendedKeyUsage = clientAuth" \
    -addext "subjectAltName = DNS:example.ptb.de" \
    -keyout cert.key -out cert.csr

echo "Signing cert..."
openssl x509 -req -sha256 -in cert.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
    -copy_extensions copyall \
    -out cert.pem -days $DAYS
