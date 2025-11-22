#/bin/sh

DEVICE="/dev/disk/by-id/google-volume-honey-01"
MOUNT_POINT="/mnt/tpot"

if ! blkid ${DEVICE}; then
    sudo mkfs.ext4 ${DEVICE}
fi

sudo mkdir -p ${MOUNT_POINT}
sudo mount ${DEVICE} ${MOUNT_POINT}