#!/bin/bash
# The purpose of this script is to set up a proxmox vm based on the Debian 13 (Trixie) Cloud Image.

CLOUD_IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
VMID=100

# make all of the following interactive
# MEMORY={INPUT:-"2048"}
# NAME={INPUT:-"default_00"}
#
# # Install and import Debian 13 (Trixie) Cloud Image
# if debian-13-generic-amd64.qcow2 != installed then
#   wget $(CLOUD_IMAGE_URL)
# qm impordisk debian-13-generic-amd64.qcow2 local
#
#
# while qemu VM with VMID = $(VMID) exists then
#   VMID=$VMID + 1
#
# while qemu VM with name = $(NAME) then
#   NAME=$(NAME) + 1
#
# qm create $(VMID) \
# --memory $(MEMORY) \
# --name $(NAME) \
# --net0 virtio,bridge=vmbr0 \
# --scsihw virtio-scsi-pci \
# --scsi0 local:vm-$(VMID)-disk-1
