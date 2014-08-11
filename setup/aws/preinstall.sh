#! /bin/bash
#Preinstall priming script for AWS installs.

sudo mkfs /dev/xvdb
sudo mount /dev/xvdb /opt

sudo mkfs /dev/xvdc
sudo mount /dev/xvdc /tmp

sudo chown -R ubuntu:ubuntu /opt
sudo chown -R ubuntu:ubuntu /tmp
mkdir /opt/src

sudo apt-get update

mv ~/gms /opt/src/gms
cd /opt/src/gms
