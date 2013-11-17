#!/bin/bash
#
#set -x

# If we don't have an sdb, nothing to do here
echo "Checking for needed devices within the vm"
test -b /dev/sdb || (echo "Could not find device /dev/sdb - aborting"; exit 0)
test -b /dev/sdc || (echo "Could not find device /dev/sdc - aborting"; exit 0)

# The following assumes that the /vagrant shared path was correctly mounted during 'vagrant up'
echo "Checking that /vagrant is mounted and the fdisk_input.txt is present"
test -f /vagrant/setup/fdisk_input.txt || (echo "Could not file /vagrant/setup/fdisk_input.txt - aborting"; exit 0)

echo "Provisioning added block devices..."
echo "Checking, creating and formatting partitions as needed"

# Do partitioning and formatting for sdb
if test -b "/dev/sdb1" ; then
  echo "Partition /dev/sdb1 already exists - not recreating"
else
  echo "Creating partition on /dev/sdb -> /dev/sdb1"
  sudo fdisk -l /dev/sdb | grep -q "^/dev/sdb1" || fdisk /dev/sdb < /vagrant/setup/fdisk_input.txt
  echo "Formatting partition sdb1 as ext4"
  sudo dumpe2fs /dev/sdb1 >/dev/null 2>&1 || mkfs.ext4 /dev/sdb1
fi

# Do partitioning and formatting for sdc
if test -b "/dev/sdc1" ; then
  echo "Partition /dev/sdc1 already exists - not recreating"
else
  echo "Creating partition on /dev/sdc -> /dev/sdc1"
  sudo fdisk -l /dev/sdc | grep -q "^/dev/sdc1" || fdisk /dev/sdc < /vagrant/setup/fdisk_input.txt
  echo "Formatting partition sdc1 as ext4"
  sudo dumpe2fs /dev/sdc1 >/dev/null 2>&1 || mkfs.ext4 /dev/sdc1
fi

# Create /opt/gms if it doesn't already exist
[ -d "/opt/gms" ] || (echo "Creating /opt/gms" && mkdir -p /opt/gms)

# Mounting plan
#/dev/sdb1 /tmp
#/dev/sdc1 /opt/gms

# fstab entries could ultimately look something like this:
#/dev/sdb1  /tmp                     ext4  defaults  0  0
#/dev/sdc1  /opt/gms                 ext4  defaults  0  0

# Mount /tmp to our first extra drive
if mount | grep -q "^/dev/sdb1" ; then
  echo "/dev/sdb1 is already mounted as /tmp"
else
  echo "Mounting /dev/sdb1 as /tmp"
  sudo mount | grep -q "^/dev/sdb1" || sudo mount -t ext4 /dev/sdb1 /tmp
fi

# Now create an fstab entry for /tmp
if grep -q "^/dev/sdb1" /etc/fstab ; then 
  echo "Already found an entry for sdb1 in /etc/fstab"
else
  echo "Adding entry for sdb1 to /etc/fstab"
  sudo echo /dev/sdb1  /tmp  ext4  defaults  0  0 >> /etc/fstab
fi

# Mount /opt/gms to our second extra drive
if mount | grep -q "^/dev/sdc1" ; then
  echo "/dev/sdc1 is already mounted as /opt/gms"
else
  echo "Mounting /dev/sdc1 as /opt/gms"
  sudo mount | grep -q "^/dev/sdc1" || sudo mount -t ext4 /dev/sdc1 /opt/gms
fi

# Now create an fstab entry for /opt/gms
if grep -q "^/dev/sdc1" /etc/fstab ; then 
  echo "Already found an entry for sdc1 in /etc/fstab"
else
  echo "Adding entry for sdc1 to /etc/fstab"
  sudo echo /dev/sdc1  /opt/gms  ext4  defaults  0  0 >> /etc/fstab
fi

