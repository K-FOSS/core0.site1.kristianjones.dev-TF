#!/bin/sh

set -e

mkdir -p /etc/harbor/ssl
cp /local/CA.pem /etc/harbor/ssl/ca.crt

/harbor/install_cert.sh

exec /usr/bin/registry_DO_NOT_USE_GC serve /local/HarborRegistry/Config.yaml