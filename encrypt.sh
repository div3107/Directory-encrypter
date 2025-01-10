#!/bin/bash

WORKDIR=$(pwd)
BACKUP_DIR="$WORKDIR-backup"
IMAGE_FILE="$WORKDIR/encrypted_container.img"
MOUNT_POINT="$WORKDIR/encrypted_mount"
PASSWORD="MySecurePassword" # Replace this with secure password handling

echo "Encrypting current working directory: $WORKDIR"

# Check if cryptsetup is installed
if ! command -v cryptsetup &> /dev/null; then
    echo "Error: cryptsetup is not installed. Install it and try again."
    exit 1
fi

# Backup existing files in the current directory
echo "Creating a backup of the current directory..."
mkdir -p "$BACKUP_DIR"
mv "$WORKDIR"/* "$BACKUP_DIR"

# Create an empty container file
echo "Creating a container file for encryption..."
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=100

# Set up encryption
echo -n $PASSWORD | cryptsetup luksFormat "$IMAGE_FILE" -
echo -n $PASSWORD | cryptsetup luksOpen "$IMAGE_FILE" encrypted_device -

# Format the encrypted container
mkfs.ext4 /dev/mapper/encrypted_device

# Mount the encrypted container
mkdir -p "$MOUNT_POINT"
mount /dev/mapper/encrypted_device "$MOUNT_POINT"

# Move backed-up files into the encrypted container
echo "Restoring files to the encrypted container..."
mv "$BACKUP_DIR"/* "$MOUNT_POINT"
rm -rf "$BACKUP_DIR"

echo "Unmounting and locking the encrypted container..."
umount "$MOUNT_POINT"
cryptsetup luksClose encrypted_device

echo "Encryption completed. To access your files, use the following steps:"
echo "1. sudo cryptsetup luksOpen $IMAGE_FILE encrypted_device"
echo "2. sudo mount /dev/mapper/encrypted_device $MOUNT_POINT"
