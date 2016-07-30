#!/bin/bash -e

# Print help when too few args are given
if [ "$#" -lt 3 ]; then
    echo -e "Usage: $0 file.tar.gpg encrypted-image.img mount-point\n\nCreates"\
    "encrypted-image.img, mounts it at mount-point,\nand extracts the contents"\
    "of file.tar.gpg to it.\n"
    exit 1
fi

FILE=$1
DISKIMAGE=$2
MOUNTPOINT=$3

# Check that the file exists
if [ ! -f $FILE ]; then
    echo "$FILE: File not found"
    exit 1
fi

# Check that the mountpoint exists
if [ ! -d $MOUNTPOINT ]; then
    echo "$MOUNTPOINT: Folder does not exist"
    exit 1
fi

# Get the size of the encrypted tar + 50% to cover the space ext4 and LUKS headers required
SIZE=$(printf "%.0f" $(echo "$(du -b $FILE | cut -f1) * 1.5" | bc))


# Create an encrypted disk image to store the extracted files

# Allocate space based on calculated size of opened tar
fallocate -l $SIZE $DISKIMAGE

# Make a key for the disk
KEY=$(dd if=/dev/urandom bs=4096 count=1)
echo $KEY | cryptsetup -d - luksFormat $DISKIMAGE

# Open the image and map it under the file name
MAPNAME=$(basename -s .tar.gpg $FILE)
echo $KEY | sudo cryptsetup luksOpen -d - $DISKIMAGE $MAPNAME


# Decrypted device is now available at /dev/mapper/$MAPNAME

# Format the device
sudo mkfs.ext4 /dev/mapper/$MAPNAME

# Mount the disk
sudo mount /dev/mapper/$MAPNAME $MOUNTPOINT

# Change ownership to the runner of the script
sudo chown -R $(whoami) $MOUNTPOINT
chmod -R u+rwx $MOUNTPOINT

# Move the data
gpg -d $FILE | tar xf - -C $MOUNTPOINT

# unset the key variable
unset KEY

echo "$1 is now mounted at $MOUNTPOINT"

sleep 2

echo "Press Ctrl-C to quit, or press any key to unmount and delete the disk image."

# TODO replace with read -n 1 var, check the variable
read -n 1

# Unmount device
sudo umount $MOUNTPOINT

# Close decryped device
sudo cryptsetup luksClose $MAPNAME

# Make the image permanently inaccessible (this will ask for confirmation)
cryptsetup erase $DISKIMAGE

# Device is safe to remove with rm
rm $DISKIMAGE

echo "Image unmounted and removed."
