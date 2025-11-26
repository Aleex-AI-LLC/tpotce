#!/bin/bash

# mount ext storage
if ! blkid "$DEVICE"; then
    mkfs.ext4 -F "${DEVICE}"
fi
mkdir -p "${MOUNT_POINT}"
mount "${DEVICE}" "${MOUNT_POINT}"
echo "${DEVICE} ${MOUNT_POINT} ext4 defaults 0 2" >> /etc/fstab

#create aleex user
USERNAME="aleex"
GROUPNAME="aleex"

# Create group if it doesn't exist
if ! getent group "$GROUPNAME" > /dev/null; then
    groupadd "$GROUPNAME"
fi
if ! id -u "$USERNAME" > /dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$GROUPNAME" "$USERNAME"
fi

usermod -aG docker "$USERNAME"

if [ "${is_master}" != "true" ]; then
    echo "Registering with master at ${master_ip}"
fi