#!/bin/bash
#
#set -x

# This script configures /dev/sd{b,c,d} to GMS-specific mount points if they exist.
# It is used by the Vagrantfile during provisioning when installing the GMS to a virtual machine.

# If we don't have an sdb, nothing to do here
echo "Checking for needed devices within the vm"
test -b /dev/sdb || (echo "Could not find device /dev/sdb - aborting"; false) || exit 0
test -b /dev/sdc || (echo "Could not find device /dev/sdc - aborting"; false) || exit 0

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
#/dev/sdd1 /opt/gms/$GENOME_SYS_ID  # optional

# fstab entries could ultimately look something like this:
#/dev/sdb1  /tmp                     ext4  defaults  0  0
#/dev/sdc1  /opt/gms                 ext4  defaults  0  0
#/dev/sdd1  /opt/gms/$GENOME_SYS_ID  ext4  defaults  0  0

# Mount /tmp to our first extra drive
if mount | grep -q "^/dev/sdb1" ; then
  echo "/dev/sdb1 is already mounted as /tmp"
else
  echo "Mounting /dev/sdb1 as /tmp"
  sudo mount | grep -q "^/dev/sdb1" || sudo mount -t ext4 /dev/sdb1 /tmp
fi
echo "ensuring /tmp has correct permissions"
sudo chmod 1777 /tmp

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

## Exit now unles there is /dev/sdd.
## The following only runs if /dev/sdd is configured on the VM
## This gives the local GMS its own disk, distinct from the one used
## to hold data sync'd from other systems.
test -b /dev/sdd || (echo "Could not find device /dev/sdd - exiting"; exit 0)

# Do partitioning and formatting for sdd
if test -b "/dev/sdd1" ; then
  echo "Partition /dev/sdd1 already exists - not recreating"
else
  echo "Creating partition on /dev/sdd -> /dev/sdd1"
  sudo fdisk -l /dev/sdd | grep -q "^/dev/sdd1" || fdisk /dev/sdd < /vagrant/setup/fdisk_input.txt
  echo "Formatting partition sdd1 as ext4"
  sudo dumpe2fs /dev/sdd1 >/dev/null 2>&1 || mkfs.ext4 /dev/sdd1
fi

## Exit now unless there is an /etc/genome/conf
test -e /etc/genome/sysid || (echo "Could not find /etc/genome/sysid.  Delaying mounting local GMS filesystem."; false) || exit 0
GENOME_SYS_ID=`cat /etc/genome/sysid`

# Mount /opt/gms to our third extra drive
# Note that this will occur with reach reboot because
if mount | grep -q "^/dev/sdd1" ; then
  echo "/dev/sdd1 is already mounted as /opt/gms"
else
  if [ -e /opt/gms/$GENOME_SYS_ID ]; then
    echo "Moving aside /opt/gms/$GENOME_SYS_ID"
    sudo mv /opt/gms/$GENOME_SYS_ID /opt/gms/tmp-$GENOME_SYS_ID
  fi
  sudo mkdir /opt/gms/$GENOME_SYS_ID
  echo "Mounting /dev/sdd1 as /opt/gms/$GENOME_SYS_ID"
  sudo mount | grep -q "^/dev/sdd1" || sudo mount -t ext4 /dev/sdd1 /opt/gms/$GENOME_SYS_ID
  if [ -e /opt/gms/tmp-$GENOME_SYS_ID ]; then
    echo "Moving /opt/gms/tmp-$GENOME_SYS_ID to the new disk."
    sudo mv /opt/gms/tmp-$GENOME_SYS_ID/* /opt/gms/$GENOME_SYS_ID 2>/dev/null
    sudo rmdir /opt/gms/tmp-$GENOME_SYS_ID
  fi
fi

# Now create an fstab entry for /opt/gms/$GENOME_SYS_ID
if grep -q "^/dev/sdd1" /etc/fstab ; then 
  echo "Already found an entry for sdd1 in /etc/fstab"
else
  echo "Adding entry for sdd1 to /etc/fstab"
  sudo echo /dev/sdd1  /opt/gms/$GENOME_SYS_ID  ext4  defaults  0  0 >> /etc/fstab
fi


