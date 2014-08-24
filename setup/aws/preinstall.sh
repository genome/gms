#! /bin/bash
#Preinstall priming script for AWS installs.

#This script assumes you are logged into an Amazon AWS instance with two ephemeral volumes present (in this case '/dev/xvdb' and '/dev/xvdc')
#For example, this will work with instance types: c3.8xlarge, r3.8xlarge, i2.2xlarge
#You may need to customize this code for your specific instance type

#Unmount the current /mnt mount point that is attached to /dev/xvdb by default
sudo umount /mnt

#Mount ephemeral storage
sudo mkfs /dev/xvdb
sudo mount /dev/xvdb /opt
sudo mkfs /dev/xvdc
sudo mount /dev/xvdc /tmp

#Make ephemeral storage mounts persistent
echo -e "LABEL=cloudimg-rootfs /  ext4 defaults  0 0\n/dev/xvdb /opt  auto  defaults,nobootwait 0 2\n/dev/xvdc /tmp  auto  defaults,nobootwait 0 2" | sudo tee  /etc/fstab

#change permissions on required drives
sudo chown -R ubuntu:ubuntu /opt
sudo chown -R ubuntu:ubuntu /tmp
chmod 1777 /tmp

sudo apt-get update

#setup install-dir
mkdir /opt/src
mv ~/gms /opt/src/gms
