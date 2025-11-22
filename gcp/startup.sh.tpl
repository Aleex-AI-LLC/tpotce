#!/bin/bash

if ! blkid "$DEVICE"; then
    mkfs.ext4 -F "${DEVICE}"
fi

mkdir -p "${MOUNT_POINT}"
mount "${DEVICE}" "${MOUNT_POINT}"
echo "${DEVICE} ${MOUNT_POINT} ext4 defaults 0 2" >> /etc/fstab

if [ "${is_master}" != "true" ]; then
    echo "Registering with master at ${master_ip}"
fi