#!/bin/bash
set -euo pipefail

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root." >&2
   exit 1
fi

# Fetching DNSname for cert
echo "==> Fetching Tailscale certs..."
NAME="$(tailscale status --json | jq '.Self.DNSName | .[:-1]' -r)"

if [[ -z "${NAME}" || "${NAME}" == "null" ]]; then
   echo "Error: Could not retrieve Tailscale DNS name. Is Tailscale running?" >&2
   exit 1
fi

# Installing cert
WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "${WORK_DIR}"' EXIT
cd "${WORK_DIR}"

echo "==> Generating certificates for ${NAME}..."
tailscale cert "${NAME}"

echo "==> Applying certificates to Proxmox VE..."
pvenode cert set "${NAME}.crt" "${NAME}.key" --force --restart

echo "==> Tailscale certs are successfully installed!"
