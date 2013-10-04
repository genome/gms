#!/bin/bash
#
#set -x

# If we don't have an sdb, nothing to do here
test -b /dev/sdb || exit 0

echo "Provisioning added block devices..."

# This assumes that the /vagrant shared path
# was correctly mounted during 'vagrant up'
sudo fdisk -l /dev/sdb | grep -q "^/dev/sdb1" || \
  fdisk /dev/sdb < /vagrant/fdisk_input.txt
#sudo fdisk -l /dev/sdc | grep -q "^/dev/sdc1" || \
#  fdisk /dev/sdc < /vagrant/fdisk_input.txt

# Check for a filesystem, make one if needed
sudo dumpe2fs /dev/sdb1 >/dev/null 2>&1 || \
  mkfs.ext4 /dev/sdb1
#sudo dumpe2fs /dev/sdc1 >/dev/null 2>&1 || \
#  mkfs.ext4 /dev/sdc1

# Let /opt/gms be our first extra drive
mkdir -p /opt/gms
mount -t ext4 /dev/sdb1 /opt/gms

# I'm not yet clear on what we want sdc1 for
# /tmp is a tmpfs filesystem and is special
# and already used by vagrant.  If we need
# more tmp space for GMS, perhaps we can use
# an environment variable to put its temp
# at GENOME_TMP=/opt/gms/tmp
