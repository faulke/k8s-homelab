#!/bin/bash
echo "Setting up .ssh keys"

# setup ssh key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /tmp/tf-packer.pub ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R ubuntu ~/.ssh

# remove cloud cfg
rm /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm /etc/cloud/cloud.cfg.d/99-installer.cfg
