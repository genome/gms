#!/bin/bash
#
#set -x

# If we don't have an sdb, nothing to do here
test -b /dev/sdb || exit 0

echo "Provisioning added block devices..."

# This assumes that the /vagrant shared path
# was correctly mounted during 'vagrant up'
echo "Creating partition on /dev/sdb -> /dev/sdb1"
sudo fdisk -l /dev/sdb | grep -q "^/dev/sdb1" || \
  fdisk /dev/sdb < /vagrant/fdisk_input.txt
echo "Creating partition on /dev/sdc -> /dev/sdc1"
sudo fdisk -l /dev/sdc | grep -q "^/dev/sdc1" || \
  fdisk /dev/sdc < /vagrant/fdisk_input.txt
echo "Creating partition on /dev/sdd -> /dev/sdd1"
sudo fdisk -l /dev/sdd | grep -q "^/dev/sdd1" || \
  fdisk /dev/sdd < /vagrant/fdisk_input.txt

# Check for a filesystem, make one if needed
echo "Formatting partition sdb1 as ext4"
sudo dumpe2fs /dev/sdb1 >/dev/null 2>&1 || \
  mkfs.ext4 /dev/sdb1
echo "Formatting partition sdc1 as ext4"
sudo dumpe2fs /dev/sdc1 >/dev/null 2>&1 || \
  mkfs.ext4 /dev/sdc1
echo "Formatting partition sdd1 as ext4"
sudo dumpe2fs /dev/sdd1 >/dev/null 2>&1 || \
  mkfs.ext4 /dev/sdd1

#Mounting plan
#/dev/sdb1 /opt/gms
#/dev/sdc1 /opt/gms/$GENOME_SYS_ID
#/dev/sdd1 /tmp

# Mount /opt/gms to our first extra drive
mkdir -p /opt/gms
mount | grep -q "^/dev/sdb1" || \
  mount -t ext4 /dev/sdb1 /opt/gms

