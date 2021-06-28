#!/usr/bin/env bash
set -e

echo "running additional config"

# setup SSL
# Self-signed server certificate
# The following commands (credits: Viktor Dukhovni) generate and install a 2048-bit RSA private key and 10-year self-signed certificate for the local Postfix system. This requires super-user privileges. (By using date-specific filenames for the certificate and key files, and updating main.cf with new filenames, a potential race condition in which the key and certificate might not match is avoided).
# @see http://www.postfix.org/TLS_README.html

echo "generating self-signed certificate"

dir="$(postconf -h config_directory)"
fqdn=$(postconf -h myhostname)
case $fqdn in /*) fqdn=$(cat "$fqdn");; esac
ymd=$(date +%Y-%m-%d)
key="${dir}/key-${ymd}.pem"; rm -f "${key}"
cert="${dir}/cert-${ymd}.pem"; rm -f "${cert}"
(umask 077; openssl genrsa -out "${key}" 2048) &&
  openssl req -new -key "${key}" \
    -x509 -subj "/CN=${fqdn}" -days 3650 -out "${cert}" &&
  postconf -e \
    "smtpd_tls_cert_file = ${cert}" \
    "smtpd_tls_key_file = ${key}"

