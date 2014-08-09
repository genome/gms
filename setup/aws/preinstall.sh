#! /bin/bash
#Preinstall priming script for AWS installs.

sudo mkfs /dev/xvdb
sudo mount /dev/xvdb /opt

sudo mkfs /dev/xvdc
sudo mount /dev/xvdc /tmp

cd /opt; mkdir src; cd src
sudo chown -R ubuntu:ubuntu /opt

sudo apt-get update
