#!/bin/bash
set -euo pipefail

# ==============================================================================
# Script Name: create-debian13-vm.sh
# Purpose: Set up a Proxmox VM based on the Debian 13 (Trixie) Cloud Image interactively.
# ==============================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (or via sudo)." >&2
  exit 1
fi

CLOUD_IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
IMAGE_FILE="debian-13-generic-amd64.qcow2"

echo "=== Proxmox Debian 13 (Trixie) VM Setup ==="

# Interactive inputs with default values
read -rp "Enter store for the ISO image [local]: " VMID
IMAGE_STORE="${IMAGE_STORE:-local}"

read -rp "Enter memory in MB [4096]: " MEMORY
MEMORY="${MEMORY:-4096}"

read -rp "Enter VM name [debian-trixie]: " NAME
NAME="${NAME:-debian-trixie}"

read -rp "Enter starting VMID [100]: " VMID
VMID="${VMID:-100}"

# 1. Check and download Debian 13 (Trixie) Cloud Image if not already present
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Downloading Debian 13 cloud image..."
  wget -O "$IMAGE_FILE" "$CLOUD_IMAGE_URL"
else
  echo "Cloud image '$IMAGE_FILE' already exists locally. Skipping download."
fi

# 2. Find the next available VMID if the current one is taken
while qm status "$VMID" &>/dev/null; do
  echo "VMID $VMID is already in use. Checking next ID..."
  VMID=$((VMID + 1))
done
echo "Using available VMID: $VMID"

# 3. Check for name collisions and append a suffix if necessary
ORIGINAL_NAME="$NAME"
COUNTER=1
while qm list | awk 'NR>1 {print $2}' | grep -qw "$NAME"; do
  NAME="${ORIGINAL_NAME}_${COUNTER}"
  COUNTER=$((COUNTER + 1))
done
if [ "$NAME" != "$ORIGINAL_NAME" ]; then
  echo "VM name '$ORIGINAL_NAME' already exists. Using unique name: $NAME"
fi

# 4. Create the base VM skeleton
echo "Creating VM $NAME ($VMID) with ${MEMORY}MB RAM..."
qm create "$VMID" \
  --memory "$MEMORY" \
  --name "$NAME" \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --serial0 socket \
  --vga serial0

# 5. Import the cloud image disk into the storage pool
echo "Importing cloud image into VM $VMID (from '$IMAGE_STORE) ..."
qm importdisk "$VMID" "$IMAGE_FILE" "$IMAGE_STORE"

# Note: qm importdisk typically registers the disk as an unused disk. 
# We attach it to scsi0 and set the boot order.
IMPORTED_DISK="${IMAGE_STORE}:vm-${VMID}-disk-0"
echo "Attaching imported disk ($IMPORTED_DISK) to scsi0..."
qm set "$VMID" --scsi0 "$IMPORTED_DISK"
qm set "$VMID" --boot "order=scsi0"

# 6. Add Cloud-Init drive for configuration (users, SSH keys, passwords)
echo "Adding Cloud-Init drive on ide2..."
qm set "$VMID" --ide2 "${IMAGE_STORE}:cloudinit"

echo "=============================================================================="
echo "Success! VM $VMID ($NAME) has been created and configured."
echo "You can now configure Cloud-Init settings in the Proxmox UI or via CLI before booting."
echo "=============================================================================="
